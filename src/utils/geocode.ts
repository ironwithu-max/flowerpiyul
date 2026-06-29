/**
 * 카카오 Geocoding API
 * 주소 문자열 → 위도(lat) / 경도(lng)
 * Supabase Edge Function 'geocode-address' 를 통해 서버사이드로 호출
 */
import { supabase } from '@/lib/supabase'

export interface Coordinates {
  lat: number
  lng: number
}

export async function geocodeAddress(address: string): Promise<Coordinates | null> {
  if (!address?.trim()) return null

  try {
    const { data, error } = await supabase.functions.invoke('geocode-address', {
      body: { address: address.trim() },
    })

    if (error || !data?.lat || !data?.lng) {
      console.warn('[geocode] 변환 실패:', address, error ?? data)
      return null
    }

    return { lat: Number(data.lat), lng: Number(data.lng) }
  } catch (e) {
    console.warn('[geocode] 오류:', e)
    return null
  }
}
