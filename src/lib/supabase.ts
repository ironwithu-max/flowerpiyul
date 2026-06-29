import { createClient } from '@supabase/supabase-js'
import type { Database } from './database.types'

// BOM(U+FEFF) 및 앞뒤 공백 제거 — Vercel 환경 변수에 BOM이 포함될 경우 방어
const stripBom = (s: string) => s.replace(/﻿/g, '').trim()
const supabaseUrl     = stripBom((import.meta.env.VITE_SUPABASE_URL     as string) || '')
const supabaseAnonKey = stripBom((import.meta.env.VITE_SUPABASE_ANON_KEY as string) || '')

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    '[Supabase] 환경 변수가 설정되지 않았습니다.\n' +
    'VITE_SUPABASE_URL 과 VITE_SUPABASE_ANON_KEY 를 .env 파일에 추가하세요.',
  )
}

/**
 * 커스텀 fetch: 헤더 값에 ISO-8859-1 범위 초과 문자(BOM·한글 등)가 포함될 경우
 * "String contains non ISO-8859-1 code point" TypeError가 발생하는 문제를 방어합니다.
 *
 * • 1차: headers를 Headers 인스턴스·배열·객체 모두 정규화하여 미리 BOM/비Latin-1 문자를 제거한 뒤 fetch
 * • 2차(fallback): 그래도 실패하면 빈 headers로 재시도
 */
function sanitiseHeaders(headers: HeadersInit | undefined): Record<string, string> | undefined {
  if (!headers) return undefined
  let entries: [string, string][]
  if (headers instanceof Headers) {
    entries = []
    headers.forEach((v, k) => entries.push([k, v]))
  } else if (Array.isArray(headers)) {
    entries = headers as [string, string][]
  } else {
    entries = Object.entries(headers as Record<string, string>)
  }
  return Object.fromEntries(
    entries.map(([k, v]) => [k, typeof v === 'string' ? v.replace(/[^\x00-\xFF]/g, '') : v]),
  )
}

function safeFetch(url: string, init?: RequestInit): Promise<Response> {
  // 사전 정규화: 모든 요청에서 비Latin-1 문자를 헤더에서 제거
  const safeInit: RequestInit | undefined = init
    ? { ...init, headers: sanitiseHeaders(init.headers) }
    : init

  try {
    return fetch(url, safeInit)
  } catch {
    // 그래도 실패하면(예: body에 문제가 있는 경우) 최후 수단으로 헤더 없이 재시도
    try {
      return fetch(url, { ...safeInit, headers: {} })
    } catch (e) {
      return Promise.reject(e)
    }
  }
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession:   true,   // localStorage 세션 유지
    autoRefreshToken: true,   // 만료 전 자동 갱신
    detectSessionInUrl: true, // 이메일 확인 콜백 처리
  },
  global: {
    fetch: safeFetch as typeof fetch,
  },
})
