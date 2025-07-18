// assets/js/app.js

// Import Chart.js
import Chart from 'chart.js/auto'; // Use 'chart.js/auto' for automatic registration of controllers, elements, scales and plugins.

let ChartHook = {
  // Store the chart instance
  chartInstance: null,

  mounted() {
    console.log("ChartHook mounted");
    this.renderChart();
  },

  updated() {
    console.log("ChartHook updated");
    this.renderChart(); // Re-render chart if data changes
  },

  destroyed() {
    console.log("ChartHook destroyed");
    if (this.chartInstance) {
      this.chartInstance.destroy(); // Clean up chart instance on destroy
    }
  },

  renderChart() {
    const chartCanvas = this.el;
    const chartDataAttr = chartCanvas.dataset.chartData;

    if (!chartDataAttr) {
      console.error("No chart data found in data-chart-data attribute.");
      return;
    }

    let data;
    try {
      data = JSON.parse(chartDataAttr);
    } catch (e) {
      console.error("Failed to parse chart data JSON:", e);
      return;
    }

    if (!data || !data.labels || !data.datasets) {
      console.error("Invalid chart data structure:", data);
      return;
    }

    // Destroy existing chart instance if it exists to prevent memory leaks
    if (this.chartInstance) {
      this.chartInstance.destroy();
    }

    // Create new chart instance
    this.chartInstance = new Chart(chartCanvas, {
      type: 'line', // Line chart for time-series data
      data: {
        labels: data.labels,
        datasets: data.datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false, // Allow canvas to fill parent container
        plugins: {
          title: {
            display: true,
            text: 'Report Data Trends'
          },
          tooltip: {
            mode: 'index',
            intersect: false,
          },
        },
        scales: {
          x: {
            title: {
              display: true,
              text: 'Date'
            }
          },
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Value'
            }
          }
        }
      }
    });
  }
};

// Add the hook to your LiveSocket
// This assumes your LiveSocket is initialized in app.js
// If not, you might need to adjust where you add this.
import { LiveSocket } from "phoenix_live_view";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { ChartHook: ChartHook }, // Register your hook here
  params: { _csrf_token: csrfToken }
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Expose liveSocket on window for browser console debug logs and for testing, etc.
window.liveSocket = liveSocket;
