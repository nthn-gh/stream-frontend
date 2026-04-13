<template>
  <div class="page">
    <!-- Page Header -->
    <div class="page-header">
      <div>
        <h1 class="h2">Reports & Analytics</h1>
        <p style="color: var(--text-muted); font-size: 14px; margin-top: 4px">
          Generate insights and track patient progress
        </p>
      </div>
    </div>

    <!-- Stat Cards -->
    <div class="stat-grid">
      <StatCard
        label="Total Patients"
        :value="String(patients.length)"
        gradient="var(--gradient-primary)"
      >
        <template #icon>
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="white"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
          </svg>
        </template>
      </StatCard>
      <StatCard
        label="Sessions This Month"
        :value="String(totalSessions)"
        gradient="var(--gradient-success)"
      >
        <template #icon>
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="white"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
            <line x1="16" y1="2" x2="16" y2="6" />
            <line x1="8" y1="2" x2="8" y2="6" />
            <line x1="3" y1="10" x2="21" y2="10" />
          </svg>
        </template>
      </StatCard>
      <StatCard
        label="Avg Adherence Rate"
        :value="`${averageAdherence}%`"
        gradient="var(--gradient-success)"
      >
        <template #icon>
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="white"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
          </svg>
        </template>
      </StatCard>
      <StatCard
        label="Active Care Plans"
        :value="String(activePlans)"
        gradient="var(--gradient-warning)"
      >
        <template #icon>
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="white"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M9 11l3 3L22 4" />
            <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
          </svg>
        </template>
      </StatCard>
    </div>

    <!-- Patient Selector -->
    <BaseCard>
      <div class="selector-header">
        <h3 class="h3">Generate Patient Report</h3>
      </div>
      <div class="selector-row">
        <select v-model="selectedPatient" class="table-select flex-1">
          <option :value="null">Select a patient...</option>
          <option v-for="patient in patients" :key="patient.id" :value="patient.id">
            {{ patient.name }}
          </option>
        </select>
        <button class="btn-primary" :disabled="!selectedPatient || isGenerating" @click="generateReport">
          {{ isGenerating ? 'Generating...' : 'Generate Report' }}
        </button>
        <button
          v-if="reportGenerated && selectedPatientData"
          class="btn-secondary"
          :disabled="isGenerating"
          @click="exportToPDF"
        >
          <Download :size="16" style="margin-right: 6px;" />
          Export PDF
        </button>
      </div>
    </BaseCard>

    <!-- Empty State -->
    <div v-if="!reportGenerated || !selectedPatient" class="empty-state">
      <FileText :size="64" style="color: var(--text-muted)" />
      <p style="color: var(--text-secondary); margin-top: var(--space-3)">
        Select a patient and generate a report to view details
      </p>
    </div>

    <!-- Report Display -->
    <div v-else-if="selectedPatientData" ref="reportRef" class="report-grid">
      <!-- Patient Info -->
      <BaseCard>
        <h3 class="h3" style="margin-bottom: var(--space-4)">Patient Information</h3>
        <div class="info-grid">
          <div class="info-item">
            <div class="info-label">NAME</div>
            <div class="info-value">{{ selectedPatientData.name }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">CONDITION</div>
            <div class="info-value">{{ selectedPatientData.condition }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">ADHERENCE RATE</div>
            <div class="info-value">{{ selectedPatientData.adherence_rate }}%</div>
          </div>
          <div class="info-item">
            <div class="info-label">STATUS</div>
            <div class="info-value" style="text-transform: capitalize">
              {{ selectedPatientData.status?.replace('_', ' ') }}
            </div>
          </div>
        </div>
      </BaseCard>

      <!-- Progress Chart -->
      <BaseCard>
        <h3 class="h3" style="margin-bottom: var(--space-4)">Progress Overview</h3>
        <div class="chart-placeholder">
          <Activity :size="32" style="color: var(--text-muted); margin-bottom: var(--space-2)" />
          <p class="caption" style="color: var(--text-muted)">Chart visualization area</p>
        </div>
      </BaseCard>

      <!-- Recent Activity -->
      <BaseCard>
        <h3 class="h3" style="margin-bottom: var(--space-4)">Recent Activity</h3>
        <div class="activity-list">
          <div class="activity-item">
            <div class="activity-dot success"></div>
            <span class="caption">Completed exercise session - 2 days ago</span>
          </div>
          <div class="activity-item">
            <div class="activity-dot info"></div>
            <span class="caption">Attended follow-up appointment - 5 days ago</span>
          </div>
          <div class="activity-item">
            <div class="activity-dot warning"></div>
            <span class="caption">Missed scheduled session - 1 week ago</span>
          </div>
        </div>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Users, Activity, TrendingUp, FileText, Download } from 'lucide-vue-next'
import { usePatientStore } from '@/stores/patientStore'
import { storeToRefs } from 'pinia'
import BaseCard from '@/components/shared/BaseCard.vue'
import StatCard from '@/components/shared/StatCard.vue'
import html2canvas from 'html2canvas'
import { jsPDF } from 'jspdf'

const patientStore = usePatientStore()
const { patients } = storeToRefs(patientStore)

const selectedPatient = ref<string | null>(null)
const isGenerating = ref(false)
const reportGenerated = ref(false)
const reportRef = ref<HTMLElement | null>(null)

const selectedPatientData = computed(() => {
  if (!selectedPatient.value) return null
  return patients.value.find((p) => p.id === selectedPatient.value)
})

const totalSessions = computed(() => {
  return patients.value.reduce((sum, p) => sum + (p.total_sessions || 0), 0)
})

const averageAdherence = computed(() => {
  if (patients.value.length === 0) return 0
  const sum = patients.value.reduce((acc, p) => acc + p.adherence_rate, 0)
  return Math.round(sum / patients.value.length)
})

const activePlans = computed(() => {
  return patients.value.filter((p) => p.status === 'active').length
})

const generateReport = async () => {
  if (!selectedPatient.value) return

  isGenerating.value = true

  // Simulate report generation with processing time
  await new Promise((resolve) => setTimeout(resolve, 800))

  reportGenerated.value = true
  isGenerating.value = false
}

const exportToPDF = async () => {
  if (!reportRef.value || !selectedPatientData.value) return

  try {
    isGenerating.value = true

    // Create canvas from the report element
    const canvas = await html2canvas(reportRef.value, {
      scale: 2,
      useCORS: true,
      logging: false,
      backgroundColor: '#ffffff',
    })

    // Calculate PDF dimensions
    const imgWidth = 210 // A4 width in mm
    const imgHeight = (canvas.height * imgWidth) / canvas.width

    // Create PDF
    const pdf = new jsPDF('p', 'mm', 'a4')
    const imgData = canvas.toDataURL('image/png')

    pdf.addImage(imgData, 'PNG', 0, 0, imgWidth, imgHeight)

    // Generate filename with patient name and date
    const patientName = selectedPatientData.value.name.replace(/\s+/g, '_')
    const date = new Date().toISOString().split('T')[0]
    const filename = `${patientName}_Report_${date}.pdf`

    pdf.save(filename)

    isGenerating.value = false
  } catch (error) {
    console.error('Error generating PDF:', error)
    isGenerating.value = false
    alert('Failed to generate PDF. Please try again.')
  }
}

onMounted(async () => {
  await patientStore.fetchPatients()
})
</script>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-2);
}

.stat-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--gap);
}

.selector-header {
  margin-bottom: var(--space-3);
}

.selector-row {
  display: flex;
  gap: var(--space-2);
  align-items: center;
}

.table-select {
  height: 36px;
  padding: 0 var(--space-3);
  background: var(--bg-input);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  font-size: 14px;
  font-family: inherit;
  outline: none;
}

.table-select:focus {
  border-color: var(--border-focus);
}

.btn-primary {
  background: var(--gradient-primary);
  color: white;
  border: none;
  cursor: pointer;
  height: 36px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  transition: opacity 0.15s;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-primary:hover {
  opacity: 0.9;
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-secondary {
  background: white;
  color: var(--primary);
  border: 1px solid var(--primary);
  cursor: pointer;
  height: 36px;
  padding: 0 var(--space-5);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.15s;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-secondary:hover {
  background: var(--primary-light);
}

.btn-secondary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-12) var(--space-4);
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
}

.report-grid {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--space-4);
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.info-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--text-muted);
}

.info-value {
  font-size: 14px;
  color: var(--text-primary);
}

.chart-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  background: var(--bg-hover);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
}

.activity-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.activity-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
}

.activity-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}

.activity-dot.success {
  background: var(--success);
}

.activity-dot.info {
  background: var(--info);
}

.activity-dot.warning {
  background: var(--warning);
}
</style>
