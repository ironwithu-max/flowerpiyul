<template>
  <svg width="52" height="52" viewBox="0 0 52 52" fill="none" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="landGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" style="stop-color:#16A34A;stop-opacity:0.25" />
        <stop offset="100%" style="stop-color:#4ADE80;stop-opacity:0.1" />
      </linearGradient>
    </defs>
    <!-- 나무 잎 -->
    <path
      d="M26 8C19 8 13 13.5 13 21c0 6 4 10.5 9.5 12V40h7V33c5.5-1.5 9.5-6 9.5-12C39 13.5 33 8 26 8Z"
      fill="url(#landGrad)" stroke="#16A34A" stroke-width="2.5" stroke-linejoin="round"
    />
    <!-- 잎맥 -->
    <path d="M26 16V32M26 22l-4.5-4.5M26 26l4.5-4.5" stroke="#16A34A" stroke-width="2" stroke-linecap="round" />
    <!-- 지면 -->
    <path d="M10 44h32" stroke="#16A34A" stroke-width="2.5" stroke-linecap="round" />
    <path d="M16 40c2-2 4-2 6 0M30 40c2-2 4-2 6 0" stroke="#16A34A" stroke-width="2" stroke-linecap="round" stroke-opacity="0.5" />
  </svg>
</template>
