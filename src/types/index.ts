export interface ServiceCategory {
  id: string
  moduleId: string
  title: string
  description: string
  statusLabel: string
  metaRight: string
  metaRightColor?: string
  variant: 'default' | 'emergency'
  accentColor: string
  glowColor: string
  route: string
  image?: string
}
