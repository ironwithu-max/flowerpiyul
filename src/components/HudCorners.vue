<template>
  <div class="hud-tl" :style="style" />
  <div class="hud-tr" :style="style" />
  <div class="hud-bl" :style="style" />
  <div class="hud-br" :style="style" />
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{ color?: string; size?: number; thickness?: number }>(),
  { color: '#ec4899', size: 15, thickness: 2 },
)

const style = computed(() => ({
  '--hud-color': props.color,
  '--hud-size': `${props.size}px`,
  '--hud-thick': `${props.thickness}px`,
}))
</script>

<style scoped>
div {
  position: absolute;
  width: var(--hud-size, 15px);
  height: var(--hud-size, 15px);
  border-color: var(--hud-color, #ec4899);
  border-style: solid;
  pointer-events: none;
  z-index: 1;
}

.hud-tl {
  top: -2px;
  left: -2px;
  border-width: var(--hud-thick) 0 0 var(--hud-thick);
}
.hud-tr {
  top: -2px;
  right: -2px;
  border-width: var(--hud-thick) var(--hud-thick) 0 0;
}
.hud-bl {
  bottom: -2px;
  left: -2px;
  border-width: 0 0 var(--hud-thick) var(--hud-thick);
}
.hud-br {
  bottom: -2px;
  right: -2px;
  border-width: 0 var(--hud-thick) var(--hud-thick) 0;
}
</style>
