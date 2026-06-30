<template>
  <ScanLines />
  <RouterView />
  <InstallPrompt />
</template>

<script setup lang="ts">
import ScanLines from '@/components/ScanLines.vue'
import InstallPrompt from '@/components/InstallPrompt.vue'
</script>
