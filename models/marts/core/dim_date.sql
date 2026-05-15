WITH date_spine AS (
    --Llamada al package
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2022-01-01' as date)",
        end_date="dateadd(year, 1, current_date())"
    ) }}
),

final_calculations AS (
    SELECT
        --Extracción de partes numéricas
        date_day AS date_actual,
        EXTRACT(year FROM date_day) AS date_year,
        EXTRACT(month FROM date_day) AS date_month,
        --Formateo de texto (Ideal para etiquetas en ejes X de Power BI/Tableau)
        TO_CHAR(date_day, 'MMMM') AS month_name,
        EXTRACT(quarter FROM date_day) AS date_quarter,
        --Usamos dayofweekiso en lugar de daypfweek para pasarlo al sistema europeo donde el lunes es día 1 de la semana
        EXTRACT(dayofweekiso FROM date_day) AS day_of_week,
            CASE WHEN EXTRACT(dayofweekiso FROM date_day) IN (6, 7) THEN TRUE 
                ELSE FALSE
            END AS is_weekend
    FROM date_spine
)

SELECT * FROM final_calculations