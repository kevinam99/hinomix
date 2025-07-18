defmodule Hinomix.Jobs.ReportIngestionJob do
  @moduledoc """
  Oban job for ingesting reports from the third-party API.
  """

  use Oban.Worker, queue: :reports, max_attempts: 3, unique: [states: Oban.Job.states()]

  alias Hinomix.ApiClient
  alias Hinomix.ReportProcessor
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    max_pages = Map.get(args, "max_pages", 7)

    Logger.info("Starting report ingestion for #{max_pages} pages")

    # Process each page of reports
    page_fetch_tasks =
      1..max_pages
      |> Enum.map(fn page ->
        Task.async(fn ->
          Logger.info("Fetching page #{page} of #{max_pages} (in parallel)")

          case ApiClient.fetch_page(page) do
            {:ok, response} ->
              processed_reports_for_page = Enum.map(response["data"], fn report_data ->
                # Data cleaning
                cleaned_report_data = %{
                   report_id: report_data["report_id"],
                   source: convert_to_valid_source(String.trim(report_data["source"])),
                   campaign_id: clean_campaign_id(report_data["campaign_id"]),
                   processed_at: DateTime.utc_now(),
                   total_revenue: clean_revenue(report_data["total_revenue"]),
                   total_clicks: clean_total_clicks(report_data["total_clicks"]),
                   report_date: report_data["report_date"]
                 }

                case ReportProcessor.process_report(cleaned_report_data) do
                  {:ok, report} ->
                    Logger.info("Processed report #{report.report_id}")
                    {:ok, report}

                  {:error, changeset} ->
                    Logger.error("Failed to process report: #{inspect(changeset.errors)}")
                    {:error, changeset}
                end
              end)
              {:ok, processed_reports_for_page}

            {:error, reason} ->
              Logger.error("Failed to fetch page #{page}: #{inspect(reason)}")
              {:error, reason}
          end
        end)
      end)

    all_processed_reports =
      Enum.flat_map(page_fetch_tasks, fn task ->
        case Task.await(task) do
          {:ok, reports_from_page} ->
            reports_from_page
          {:error, _reason} ->
            []
        end
      end)

    successful = Enum.count(all_processed_reports, fn
      {:ok, _} -> true
      _ -> false
    end)

    Logger.info("Report ingestion completed. Processed #{successful} reports successfully.")

    # Schedule a discrepancy check job after ingestion
    %{"delay" => 10}
    |> Hinomix.Jobs.DiscrepancyCheckJob.new(schedule_in: 10)
    |> Oban.insert()

    :ok
  end

  defp convert_to_valid_source(source) when source in ["fb", "facebook"], do: "facebook"
  defp convert_to_valid_source(source) when source in ["twitter", "twiiter"], do: "twitter"
  defp convert_to_valid_source(source) when source in ["google", "Google"], do: "google"

  defp clean_revenue("$" <> revenue), do: revenue
  defp clean_revenue(revenue) when is_binary(revenue), do: String.replace(revenue, ",", "")

  defp clean_total_clicks(<<clicks::binary>>), do: String.to_integer(clicks)
  defp clean_total_clicks(nil), do: 0
  defp clean_total_clicks(clicks), do: clicks

  defp clean_campaign_id(campaign_id) do
    campaign_id
    |> String.trim()
    |> String.downcase()
    |> String.split("campaign")
    |> Enum.join("_")
  end

end
