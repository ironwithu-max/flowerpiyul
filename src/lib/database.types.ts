// ============================================================
//  FIXHOME  ·  Supabase Database Types
//  supabase gen types typescript --project-id <id> 로 자동 생성 가능
// ============================================================

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

/* ── Row helpers ─────────────────────────────── */
type Row<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row']

type Insert<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert']

type Update<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update']

/* ── Exported convenience types ──────────────── */
export type Profile             = Row<'profiles'>
export type ProfileInsert       = Insert<'profiles'>
export type ProfileUpdate       = Update<'profiles'>

export type CorporateApplication       = Row<'corporate_applications'>
export type CorporateApplicationInsert = Insert<'corporate_applications'>
export type CorporateApplicationUpdate = Update<'corporate_applications'>

export type CorporateDocument       = Row<'corporate_documents'>
export type CorporateDocumentInsert = Insert<'corporate_documents'>

export type ServiceRequest       = Row<'service_requests'>
export type ServiceRequestInsert = Insert<'service_requests'>
export type ServiceRequestUpdate = Update<'service_requests'>

export type Quote       = Row<'quotes'>
export type QuoteInsert = Insert<'quotes'>
export type QuoteUpdate = Update<'quotes'>

export type Invoice       = Row<'invoices'>
export type InvoiceInsert = Insert<'invoices'>

export type Payment       = Row<'payments'>
export type PaymentInsert = Insert<'payments'>

export type Review       = Row<'reviews'>
export type ReviewInsert = Insert<'reviews'>

export type Notification       = Row<'notifications'>
export type NotificationInsert = Insert<'notifications'>

export type GalleryPhoto       = Row<'gallery_photos'>
export type GalleryPhotoInsert = Insert<'gallery_photos'>
export type GalleryPhotoUpdate = Update<'gallery_photos'>

/* ── Literal types ───────────────────────────── */
export type UserType          = 'general' | 'corporate' | 'admin'
export type ApplicationStatus = 'pending' | 'approved' | 'rejected'
export type RequestStatus     = 'open' | 'quoted' | 'in_progress' | 'completed' | 'cancelled'
export type ServiceCategory   = 'emergency_repair' | 'interior' | 'renovation' | 'electric' | 'plumbing' | 'cleaning' | 'smart_home' | 'ev-solar' | 'furniture' | 'landscaping' | 'other'
export type QuoteStatus       = 'pending' | 'accepted' | 'rejected' | 'expired'
export type InvoiceStatus     = 'unpaid' | 'pending_confirm' | 'paid' | 'cancelled' | 'refunded'
export type PaymentStatus     = 'pending' | 'completed' | 'failed' | 'refunded'
export type NotificationType  = 'NEW_QUOTE' | 'QUOTE_ACCEPTED' | 'PAYMENT_COMPLETE' | 'WORK_COMPLETED' | 'REVIEW_RECEIVED' | 'MEMBERSHIP_APPROVAL'

/* ── Full Database Schema ────────────────────── */
export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id:           string
          name:         string
          phone:        string | null
          type:         UserType
          company_name: string | null
          avatar_url:   string | null
          created_at:   string
          updated_at:   string
        }
        Insert: {
          id:            string
          name:          string
          phone?:        string | null
          type?:         UserType
          company_name?: string | null
          avatar_url?:   string | null
          created_at?:   string
          updated_at?:   string
        }
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>
      }

      corporate_applications: {
        Row: {
          id:               number
          user_id:          string | null
          company_name:     string
          biz_number:       string
          ceo_name:         string
          biz_type:         string
          service_area:     string
          contact_name:     string
          contact_phone:    string
          contact_email:    string
          status:           ApplicationStatus
          rejection_reason: string | null
          internal_memo:    string | null
          submitted_at:     string
          reviewed_at:      string | null
          reviewed_by:      string | null
        }
        Insert: {
          user_id?:          string | null
          company_name:      string
          biz_number:        string
          ceo_name:          string
          biz_type:          string
          service_area:      string
          contact_name:      string
          contact_phone:     string
          contact_email:     string
          status?:           ApplicationStatus
          rejection_reason?: string | null
          internal_memo?:    string | null
          submitted_at?:     string
          reviewed_at?:      string | null
          reviewed_by?:      string | null
        }
        Update: Partial<Database['public']['Tables']['corporate_applications']['Insert']>
      }

      corporate_documents: {
        Row: {
          id:             number
          application_id: number
          document_name:  string
          storage_path:   string
          is_required:    boolean
          uploaded_at:    string
        }
        Insert: {
          application_id: number
          document_name:  string
          storage_path:   string
          is_required?:   boolean
          uploaded_at?:   string
        }
        Update: Partial<Database['public']['Tables']['corporate_documents']['Insert']>
      }

      service_requests: {
        Row: {
          id:          number
          user_id:     string
          title:       string
          description: string | null
          category:    ServiceCategory
          address:     string
          budget_min:  number | null
          budget_max:  number | null
          status:      RequestStatus
          created_at:  string
          updated_at:  string
        }
        Insert: {
          user_id:      string
          title:        string
          description?: string | null
          category:     ServiceCategory
          address:      string
          budget_min?:  number | null
          budget_max?:  number | null
          status?:      RequestStatus
          created_at?:  string
          updated_at?:  string
        }
        Update: Partial<Database['public']['Tables']['service_requests']['Insert']>
      }

      quotes: {
        Row: {
          id:             number
          request_id:     number
          partner_id:     string
          amount:         number
          description:    string | null
          estimated_days: number | null
          status:         QuoteStatus
          created_at:     string
        }
        Insert: {
          request_id:      number
          partner_id:      string
          amount:          number
          description?:    string | null
          estimated_days?: number | null
          status?:         QuoteStatus
          created_at?:     string
        }
        Update: Partial<Database['public']['Tables']['quotes']['Insert']>
      }

      invoices: {
        Row: {
          id:         number
          quote_id:   number | null
          request_id: number | null
          user_id:    string | null
          partner_id: string | null
          amount:     number
          status:     InvoiceStatus
          created_at: string
        }
        Insert: {
          quote_id?:   number | null
          request_id?: number | null
          user_id?:    string | null
          partner_id?: string | null
          amount:      number
          status?:     InvoiceStatus
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['invoices']['Insert']>
      }

      payments: {
        Row: {
          id:         number
          invoice_id: number
          amount:     number
          method:     string
          status:     PaymentStatus
          paid_at:    string | null
          created_at: string
        }
        Insert: {
          invoice_id: number
          amount:     number
          method:     string
          status?:    PaymentStatus
          paid_at?:   string | null
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['payments']['Insert']>
      }

      reviews: {
        Row: {
          id:         number
          request_id: number | null
          user_id:    string | null
          partner_id: string | null
          rating:     number
          comment:    string | null
          created_at: string
        }
        Insert: {
          request_id?: number | null
          user_id?:    string | null
          partner_id?: string | null
          rating:      number
          comment?:    string | null
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['reviews']['Insert']>
      }

      notifications: {
        Row: {
          id:         number
          user_id:    string
          type:       NotificationType
          title:      string
          body:       string
          link:       string
          is_read:    boolean
          created_at: string
        }
        Insert: {
          user_id:     string
          type:        NotificationType
          title:       string
          body:        string
          link?:       string
          is_read?:    boolean
          created_at?: string
        }
        Update: Partial<Database['public']['Tables']['notifications']['Insert']>
      }

      gallery_photos: {
        Row: {
          id:           number
          image_url:    string
          storage_path: string | null
          caption:      string | null
          sort_order:   number
          is_visible:   boolean
          created_at:   string
        }
        Insert: {
          image_url:     string
          storage_path?: string | null
          caption?:      string | null
          sort_order?:   number
          is_visible?:   boolean
          created_at?:   string
        }
        Update: Partial<Database['public']['Tables']['gallery_photos']['Insert']>
      }
    }

    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}
