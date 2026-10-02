<template>
  <div class="page">
    <PageHeader
      title="Reports"
      subtitle="Generate and export clinical reports for patients, clinics, or funders."
    />

    <div class="sl-grid sl-cols-4" style="margin-bottom: var(--spacing-6)">
      <StatCard label="Total patients" :value="String(patients.length)" icon-bg="var(--accent-blue-soft)" icon-color="var(--color-primary)">
        <template #icon><Users :size="20" /></template>
      </StatCard>
      <StatCard label="Sessions this month" :value="String(totalSessions)" icon-bg="var(--accent-teal-bg)" icon-color="var(--color-teal)">
        <template #icon><Calendar :size="20" /></template>
      </StatCard>
      <StatCard label="Avg. adherence rate" :value="`${averageAdherence}%`" icon-bg="var(--accent-teal-bg)" icon-color="var(--color-teal)">
        <template #icon><TrendingUp :size="20" /></template>
      </StatCard>
      <StatCard label="Active care plans" :value="String(activePlans)" icon-bg="var(--accent-purple-bg)" icon-color="var(--accent-purple)">
        <template #icon><CheckSquare :size="20" /></template>
      </StatCard>
    </div>

    <div class="sl-card" style="display: flex; gap: var(--spacing-4); flex-wrap: wrap; align-items: flex-end">
      <div class="sl-field" style="width: 200px">
        <label for="rp-range">Date range</label>
        <select id="rp-range" v-model="rangeKey" class="sl-select">
          <option value="30">Last 30 days</option>
          <option value="90">Last 90 days</option>
          <option value="quarter">This quarter</option>
        </select>
      </div>
      <div class="sl-field" style="width: 220px">
        <label for="rp-patient">Patient</label>
        <select id="rp-patient" v-model="selectedPatientId" class="sl-select">
          <option :value="null">Select a patient…</option>
          <option v-for="patient in patients" :key="patient.id" :value="patient.id">{{ patient.name }}</option>
        </select>
      </div>
      <AppButton :disabled="!selectedPatientId || isGenerating" :loading="isGenerating" @click="applyFilters">
        Apply filters
      </AppButton>
    </div>

    <p v-if="reportError" class="t-body-sm" style="color: var(--color-error-text); margin-top: var(--spacing-3)">{{ reportError }}</p>
    <p v-else-if="!selectedPatientId" class="t-body-sm text-secondary" style="margin-top: var(--spacing-3)">
      Select a patient and apply filters to enable the reports below.
    </p>

    <div class="sl-grid sl-cols-2" style="margin-top: var(--spacing-6)">
      <button
        v-for="type in reportTypes"
        :key="type.key"
        type="button"
        class="sl-card report-card"
        :disabled="!reportData || isGenerating"
        @click="downloadReport()"
      >
        <div style="display: flex; align-items: center; justify-content: space-between; gap: var(--spacing-3)">
          <div style="display: flex; align-items: center; gap: 12px">
            <div class="report-card__icon" :style="{ background: type.iconBg }">
              <component :is="type.icon" :size="20" :style="{ color: type.iconColor }" />
            </div>
            <h2 class="t-h4">{{ type.title }}</h2>
          </div>
          <span class="sl-btn-icon" aria-hidden="true"><Download :size="18" /></span>
        </div>
        <p class="t-body-sm text-secondary" style="margin-top: var(--spacing-3); text-align: left">{{ type.description }}</p>
      </button>
    </div>

    <div v-if="reportData" id="report-detail" class="sl-card" style="margin-top: var(--spacing-6); display: flex; flex-direction: column; gap: var(--spacing-6)">
      <div>
        <h2 class="t-h4" style="margin-bottom: var(--spacing-4)">{{ reportData.patient.name }} — report summary</h2>
        <div class="sl-grid sl-cols-4">
          <div><div class="t-label text-secondary">Total sessions</div><div class="t-body-md">{{ reportData.metrics.total_sessions }}</div></div>
          <div><div class="t-label text-secondary">Adherence</div><div class="t-body-md">{{ reportData.metrics.adherence }}%</div></div>
          <div><div class="t-label text-secondary">Avg. accuracy</div><div class="t-body-md">{{ Math.round(reportData.metrics.avg_accuracy) }}%</div></div>
          <div><div class="t-label text-secondary">ROM change</div><div class="t-body-md">{{ reportData.metrics.rom_improvement >= 0 ? '+' : '' }}{{ reportData.metrics.rom_improvement }}°</div></div>
        </div>
      </div>

      <div v-if="romChartData.labels.length">
        <h3 class="t-label text-secondary" style="margin-bottom: var(--spacing-3)">Range of motion over time</h3>
        <div style="height: 220px">
          <Line :data="romChartData" :options="chartOptions" />
        </div>
      </div>

      <div v-if="reportData.exercise_breakdown.length">
        <h3 class="t-label text-secondary" style="margin-bottom: var(--spacing-3)">Exercise breakdown</h3>
        <AppTable :columns="[{ key: 'exercise', label: 'Exercise' }, { key: 'sessions', label: 'Sessions' }, { key: 'accuracy', label: 'Avg. accuracy' }]">
          <tr v-for="row in reportData.exercise_breakdown" :key="row.exercise_name">
            <td class="t-body-md">{{ row.exercise_name }}</td>
            <td>{{ row.sessions_count }}</td>
            <td>{{ Math.round(row.avg_accuracy) }}%</td>
          </tr>
        </AppTable>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Tooltip,
  Legend,
} from 'chart.js'
import {
  Users,
  Calendar,
  TrendingUp,
  CheckSquare,
  Download,
  Award,
  Clipboard,
} from 'lucide-vue-next'
import { usePatientStore } from '@/stores/patientStore'
import { useReportStore } from '@/stores/reportStore'
import { storeToRefs } from 'pinia'
import AppButton from '@/components/shared/AppButton.vue'
import AppTable from '@/components/shared/AppTable.vue'
import StatCard from '@/components/shared/StatCard.vue'
import PageHeader from '@/components/shared/PageHeader.vue'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Tooltip, Legend)

const patientStore = usePatientStore()
const reportStore = useReportStore()
const { patients } = storeToRefs(patientStore)
const { data: reportData, isGenerating, error: reportError } = storeToRefs(reportStore)

const selectedPatientId = ref<string | null>(null)
const rangeKey = ref<'30' | '90' | 'quarter'>('30')

const reportTypes = [
  {
    key: 'progress',
    title: 'Monthly progress summary',
    description: 'Adherence, accuracy, and ROM change for the selected patient over the chosen date range.',
    icon: TrendingUp,
    iconBg: 'var(--accent-blue-soft)',
    iconColor: 'var(--color-primary)',
  },
  {
    key: 'adherence',
    title: 'Adherence report',
    description: 'Session completion vs. assigned schedule for the selected patient.',
    icon: CheckSquare,
    iconBg: 'var(--accent-teal-bg)',
    iconColor: 'var(--color-teal)',
  },
  {
    key: 'completion-log',
    title: 'Exercise completion log',
    description: 'Full session-by-session log with sets, reps, and accuracy for audit or insurance.',
    icon: Clipboard,
    iconBg: 'var(--accent-purple-bg)',
    iconColor: 'var(--accent-purple)',
  },
  {
    key: 'outcomes',
    title: 'Clinical outcomes report',
    description: 'ROM, strength, and balance score trends for referring physicians.',
    icon: Award,
    iconBg: 'var(--accent-orange-bg)',
    iconColor: 'var(--accent-orange)',
  },
] as const

const totalSessions = computed(() => patients.value.reduce((sum, p) => sum + (p.total_sessions || 0), 0))
const averageAdherence = computed(() => {
  if (!patients.value.length) return 0
  return Math.round(patients.value.reduce((sum, p) => sum + (p.adherence_rate ?? 0), 0) / patients.value.length)
})
const activePlans = computed(() => patients.value.filter((p) => p.status === 'active').length)

function dateRange() {
  const end = new Date()
  const start = new Date()
  if (rangeKey.value === '30') start.setDate(end.getDate() - 30)
  else if (rangeKey.value === '90') start.setDate(end.getDate() - 90)
  else start.setMonth(Math.floor(end.getMonth() / 3) * 3, 1)
  const toIso = (d: Date) => d.toISOString().split('T')[0] as string
  return { start: toIso(start), end: toIso(end) }
}

async function applyFilters() {
  if (!selectedPatientId.value) return
  const { start, end } = dateRange()
  reportStore.updateConfig({
    type: 'progress',
    patient_id: selectedPatientId.value,
    start_date: start,
    end_date: end,
  })
  await reportStore.generateReport()
}

async function downloadReport() {
  if (!reportData.value) {
    await applyFilters()
  }
  if (!reportData.value) return
  await reportStore.exportPDF('report-detail')
}

const romChartData = computed(() => ({
  labels: (reportData.value?.chart_data.rom_progress ?? []).map((p) =>
    new Date(p.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
  ),
  datasets: [
    {
      label: 'ROM (degrees)',
      data: (reportData.value?.chart_data.rom_progress ?? []).map((p) => p.value),
      borderColor: '#0EA5E9',
      backgroundColor: 'rgba(14,165,233,0.12)',
      tension: 0.3,
      fill: true,
    },
  ],
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: { legend: { display: false } },
}

onMounted(async () => {
  await patientStore.fetchPatients()
})
</script>

<style scoped>
.report-card {
  text-align: left;
  cursor: pointer;
  border: 1px solid var(--color-slate-200);
  font-family: inherit;
  transition: border-color 0.2s ease, box-shadow 0.2s ease, transform 0.2s ease;
}
.report-card:hover:not(:disabled) {
  border-color: var(--color-slate-300);
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}
.report-card:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.report-card__icon {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-lg);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
</style>
