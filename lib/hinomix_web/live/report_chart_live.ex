defmodule HinomixWeb.ReportChartLive do
  use HinomixWeb, :live_view

  alias Hinomix.Repo
  alias Hinomix.Reports.Report
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    # Fetch and aggregate data for the chart
    chart_data = fetch_chart_data()

    # Assign the transformed data to the socket
    {:ok, assign(socket, :chart_data, chart_data)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-3xl font-bold mb-6 text-center text-gray-800">Report Analytics Dashboard</h1>

      <div class="bg-white shadow-lg rounded-lg p-6">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">Daily Clicks and Revenue</h2>
        <div class="relative h-96">
          <%!-- The canvas element where Chart.js will render the chart --%>
          <%!-- phx-hook="ChartHook" tells LiveView to use our JavaScript hook --%>
          <canvas id="report-chart" phx-hook="ChartHook"
                  data-chart-data={Jason.encode!(assigns.chart_data)}>
          </canvas>
        </div>
      </div>

      <div class="mt-8 bg-white shadow-lg rounded-lg p-6">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">Raw Data Overview</h2>
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Report Date
              </th>
               <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Source
              </th>
               <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Campaign ID
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Total Clicks
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Total Revenue
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for data <- assigns.chart_data.raw_data do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  <%= Date.to_string(data.date) %>
                </td>
                 <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= data.source %>
                </td>
                 <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= data.campaign_id %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= data.total_clicks %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <%= Decimal.to_float(data.total_revenue) |> :erlang.float_to_binary(decimals: 2) %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # Helper function to fetch and transform data
  defp fetch_chart_data() do
    # Query to sum total_clicks and total_revenue per report_date
    raw_data =
      Repo.all(
        from r in Report,
          select: %{
            date: r.report_date,
            total_clicks: r.total_clicks,
            total_revenue: r.total_revenue,
            source: r.source,
            campaign_id: r.campaign_id
          },
          order_by: r.report_date # Ensure data is ordered for the chart
      )

    # Transform raw data into Chart.js friendly format
    labels = Enum.map(raw_data, &Date.to_string(&1.date))
    total_clicks_data = Enum.map(raw_data, &(&1.total_clicks || 0)) # Handle nil clicks, default to 0
    total_revenue_data = Enum.map(raw_data, &Decimal.to_float(&1.total_revenue || Decimal.new(0))) # Handle nil revenue, default to 0.0

    chart_js_datasets = [
      %{
        label: "Total Clicks",
        data: total_clicks_data,
        borderColor: "rgb(75, 192, 192)",
        backgroundColor: "rgba(75, 192, 192, 0.5)",
        fill: false,
        tension: 0.3 # Smooth lines
      },
      %{
        label: "Total Revenue",
        data: total_revenue_data,
        borderColor: "rgb(255, 99, 132)",
        backgroundColor: "rgba(255, 99, 132, 0.5)",
        fill: false,
        tension: 0.3
      }
    ]

    # Return a map containing both Chart.js data and the raw data for the table
    %{
      labels: labels,
      datasets: chart_js_datasets,
      raw_data: raw_data # Include raw data for the table display
    }
  end

  # Example of how you might handle updates (e.g., if you had filters)
  # @impl true
  # def handle_event("update_chart", _params, socket) do
  #   chart_data = fetch_chart_data()
  #   {:noreply, assign(socket, :chart_data, chart_data)}
  # end
end
