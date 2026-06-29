// ============================================================
//  FIXHOME · AI 표준견적 생성 Edge Function
//
//  입력(JSON):
//    { category, title, description, isEmergency?, timeBand?, distanceKm?, requestId?, debug? }
//      category : 'electric'|'electrical'|'emergency'|'emergency_repair'
//      timeBand : 'day'|'evening'|'night'|'midnight'|'dawn'  (기본 day)
//
//  매핑 전략 (비용 최소화): 키워드 우선 → 약하거나 없을 때만 AI 호출.
//    1) 키워드로 강하게 매칭되면 그대로 사용 (무료)
//    2) 약하거나 매칭 없음 + ANTHROPIC_API_KEY 있으면 → Claude로 매핑 (소액)
//    3) AI도 실패하면 약한 키워드라도 사용, 그래도 없으면 현장확정 + 미스 로깅
//
//  자재 = 부자재(시공소모품)만. 제품(주자재)은 고객 별도 참고가.
//
//  Supabase Secrets:
//    ANTHROPIC_API_KEY : (선택) 없으면 키워드만으로 동작 (무료)
//    ANTHROPIC_MODEL   : (선택) 기본 claude-haiku-4-5-20251001
// ============================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

const RATES: Record<string, number> = { general: 30000, specialized: 50000, special: 80000 }
const TYPE_KR: Record<string, string> = { general: '일반', specialized: '전문', special: '특수' }
const TIME_MULT: Record<string, number> = { day: 1.0, evening: 1.2, night: 1.5, midnight: 2.0, dawn: 1.2 }
const BASE = 25000
const EMG = 30000
const KW_STRONG = 3   // 키워드 점수가 이 이상이면 AI 없이 확정 (특정 단일 키워드 일치)

interface PricingItem {
  code: string; category: string; subgroup: string | null; item_name: string
  aliases: string[]; labor_type: string; labor_hours: number
  submaterial_min: number | null; submaterial_max: number | null
  product_ref_min: number | null; product_ref_max: number | null
  is_field_quote: boolean
}

function normCategory(c: string): 'electric' | 'emergency' {
  if (/emergency|긴급/i.test(c)) return 'emergency'
  return 'electric'
}

/* ── 키워드 매핑 (무료) ── */
function keywordMatch(text: string, items: PricingItem[]): { code: string; score: number } | null {
  const t = text.toLowerCase()
  let best: { code: string; score: number } | null = null
  for (const it of items) {
    let score = 0
    for (const kw of [it.item_name, ...(it.aliases ?? [])]) {
      const k = (kw ?? '').toLowerCase().trim()
      if (k.length >= 2 && t.includes(k)) score += k.length
    }
    if (score > 0 && (!best || score > best.score)) best = { code: it.code, score }
  }
  return best
}

/* ── Claude API 매핑 (애매할 때만) ── */
async function aiMatch(
  text: string, items: PricingItem[], apiKey: string, model: string,
): Promise<{ code: string; confidence: number; quantity: number; hours_override: number | null; reason: string } | { _error: string }> {
  const list = items.map(i => `${i.code}: ${i.item_name} (별칭: ${i.aliases.join(', ')})`).join('\n')
  const sys = `너는 픽스홈(가정/상업 수리 플랫폼)의 견적 분류기다. 고객의 요청 글을 읽고 아래 "작업항목 목록" 중 가장 잘 맞는 항목 1개의 코드를 고른다.
- 오타·구어체·간접표현도 의미로 판단한다 (예: "물 계속 흘러요" → 변기 부속 교체).
- 적합한 항목이 정말 없으면 code 를 "none" 으로 한다.
- hours_override 는 글에서 작업량이 표준과 명확히 다를 때만(예: "여러 개", "전체") 숫자로, 아니면 null.
- quantity 는 동일 작업 개수(기본 1).
반드시 select_item 도구로만 답한다.`
  const body = {
    model,
    max_tokens: 300,
    system: sys,
    tool_choice: { type: 'tool', name: 'select_item' },
    tools: [{
      name: 'select_item',
      description: '고객 요청에 가장 맞는 작업항목 코드를 선택',
      input_schema: {
        type: 'object',
        properties: {
          code: { type: 'string', description: '선택한 항목 코드 또는 "none"' },
          confidence: { type: 'number', description: '확신도 0~1' },
          quantity: { type: 'integer', description: '동일 작업 개수(기본 1)' },
          hours_override: { type: ['number', 'null'], description: '표준과 다를 때만 시간, 아니면 null' },
          reason: { type: 'string', description: '한 줄 근거(한국어)' },
        },
        required: ['code', 'confidence', 'reason'],
      },
    }],
    messages: [{ role: 'user', content: `[작업항목 목록]\n${list}\n\n[고객 요청]\n${text}` }],
  }
  let res: Response
  try {
    res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
      body: JSON.stringify(body),
    })
  } catch (e) {
    return { _error: `fetch 실패: ${e instanceof Error ? e.message : e}` }
  }
  if (!res.ok) {
    const errText = await res.text().catch(() => '')
    console.warn('[generate-estimate] Anthropic API 오류:', res.status, errText)
    return { _error: `http ${res.status}: ${errText.slice(0, 160)}` }
  }
  const data = await res.json()
  const tool = (data.content ?? []).find((c: { type: string }) => c.type === 'tool_use')
  if (!tool) return { _error: 'no tool_use' }
  const inp = tool.input
  return {
    code: String(inp.code ?? 'none'),
    confidence: Number(inp.confidence ?? 0),
    quantity: Math.max(1, Number(inp.quantity ?? 1)),
    hours_override: inp.hours_override == null ? null : Number(inp.hours_override),
    reason: String(inp.reason ?? ''),
  }
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  try {
    const { category, title = '', description = '', isEmergency = false, timeBand = 'day', distanceKm, requestId, debug = false } =
      await req.json()
    if (!category) return json({ error: 'category가 필요합니다.' }, 400)

    const text = `${title}\n${description}`.trim()
    if (text.length < 5) return json({ error: '요청 내용이 너무 짧습니다.' }, 400)

    const cat = normCategory(String(category))
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: items, error: itemErr } = await supabase
      .from('pricing_items').select('*')
      .eq('is_active', true).in('category', [cat, 'commercial'])
    if (itemErr) return json({ error: `단가표 조회 실패: ${itemErr.message}` }, 500)
    if (!items || items.length === 0) return json({ error: '활성 단가 항목이 없습니다. 시드를 적용하세요.' }, 500)
    const list = items as PricingItem[]

    const apiKey = Deno.env.get('ANTHROPIC_API_KEY')
    const model = Deno.env.get('ANTHROPIC_MODEL') ?? 'claude-haiku-4-5-20251001'
    const diag: Record<string, unknown> = { itemCount: list.length, apiKeyPresent: !!apiKey }

    let code = 'none', confidence = 0, quantity = 1, hoursOverride: number | null = null
    let reason = '', method = 'none'

    /* 1) 키워드 우선 (무료) */
    const kw = keywordMatch(text, list)
    diag.kwCode = kw?.code ?? null
    diag.kwScore = kw?.score ?? 0
    if (kw && kw.score >= KW_STRONG) {
      code = kw.code; confidence = 0.65; reason = '키워드 매칭'; method = 'keyword'
    }

    /* 2) 약하거나 없음 → AI (키 있을 때만) */
    if (code === 'none' && apiKey) {
      const ai = await aiMatch(text, list, apiKey, model)
      if ('_error' in ai) {
        diag.aiError = ai._error
      } else if (ai.code !== 'none') {
        code = ai.code; confidence = ai.confidence; quantity = ai.quantity
        hoursOverride = ai.hours_override; reason = ai.reason; method = 'ai'
      }
    }

    /* 3) AI도 실패 → 약한 키워드라도 사용 */
    if (code === 'none' && kw) {
      code = kw.code; confidence = 0.4; reason = '키워드 약매칭'; method = 'keyword-weak'
    }

    const item = list.find(i => i.code === code)
    diag.method = method
    diag.finalCode = code

    /* 매핑 실패 → 미스 로그 + 현장확정 */
    if (!item) {
      await supabase.from('estimate_misses').insert({
        request_id: requestId ?? null, category: cat, raw_text: text.slice(0, 500),
      })
      return json({
        matched: false, fallback: '현장확정',
        message: '표준 항목에 매칭되지 않아 현장 확인 견적이 필요합니다.',
        ...(debug ? { _debug: diag } : {}),
      })
    }

    /* 견적 계산 */
    const rate = RATES[item.labor_type] ?? 30000
    const hours = hoursOverride && hoursOverride > 0 ? hoursOverride : Number(item.labor_hours)
    const mult = TIME_MULT[timeBand] ?? 1.0
    const labor = Math.round(rate * hours * mult)
    const base = BASE + (isEmergency ? EMG : 0)

    const product = item.product_ref_min != null
      ? { min: item.product_ref_min, max: item.product_ref_max, note: '제품은 고객 별도(참고가)' }
      : null
    const disclaimer = '참고용 예상 시공 견적입니다. 제품(자재)은 고객 준비 또는 별도 안내, 실제 금액은 현장 확인 후 확정됩니다.'

    /* 현장확정(부자재 변동) 항목 */
    if (item.is_field_quote || item.submaterial_min == null) {
      return json({
        matched: true, isFieldQuote: true, method, confidence, reason,
        item: { code: item.code, name: item.item_name, subgroup: item.subgroup, laborType: TYPE_KR[item.labor_type] },
        breakdown: { dispatch: BASE, emergency: isEmergency ? EMG : 0, labor, submaterial: '현장확정' },
        laborSubtotal: base + labor,
        product, disclaimer,
        note: '부자재가 현장 상황에 따라 변동되어 시공비는 현장 확인 후 확정됩니다.',
        ...(debug ? { _debug: diag } : {}),
      })
    }

    const smin = item.submaterial_min, smax = item.submaterial_max ?? item.submaterial_min
    const subMid = Math.round((smin + smax) / 2)
    const constructionTotal = base + labor + subMid

    return json({
      matched: true, isFieldQuote: false, method, confidence, reason,
      item: { code: item.code, name: item.item_name, subgroup: item.subgroup, laborType: TYPE_KR[item.labor_type] },
      quantity, hours, timeBand,
      breakdown: { dispatch: BASE, emergency: isEmergency ? EMG : 0, labor, submaterialMid: subMid, submaterialMin: smin, submaterialMax: smax },
      constructionTotal,
      range: { low: base + labor + smin, high: base + labor + smax },
      distance: distanceKm
        ? { km: distanceKm, fee: Math.max(0, Math.round(distanceKm) - 5) * 2000, note: '기본 5km 무상 · 초과분 km당 ₩2,000 · 콜 수락 후 정산' }
        : { note: '기본 5km 무상 · 초과분 km당 ₩2,000 · 콜 수락 후 정산' },
      product,
      disclaimer,
      ...(debug ? { _debug: diag } : {}),
    })
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : '알 수 없는 오류'
    console.error('[generate-estimate]', message)
    return json({ error: message }, 500)
  }
})
