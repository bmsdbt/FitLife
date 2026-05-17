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
        --Generación de una subrrogate key para la dim_date
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} as sk_date,
        --Extracción de partes numéricas
        date_day AS date_actual,
        EXTRACT(day from date_day) as date_day,
         --Formateo de texto (Ideal para etiquetas en ejes X de Power BI/Tableau)
        CASE EXTRACT(dayofweekiso FROM date_day)
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
            WHEN 7 THEN 'Sunday'
        END AS day_name,
        EXTRACT(weekiso from date_day) as date_week,
        EXTRACT(month FROM date_day) as date_month,
        --Formateo de texto (Ideal para etiquetas en ejes X de Power BI/Tableau)
        TO_CHAR(date_day, 'MMMM') as month_name,
        EXTRACT(year FROM date_day) as date_year,
        EXTRACT(quarter FROM date_day) as date_quarter,
        --Usamos dayofweekiso en lugar de daypfweek para pasarlo al sistema europeo donde el lunes es día 1 de la semana
        EXTRACT(dayofweekiso FROM date_day) as day_of_week,
            CASE WHEN EXTRACT(dayofweekiso FROM date_day) IN (6, 7) THEN TRUE 
                ELSE FALSE
            END as is_weekend
    FROM date_spine
)

SELECT * FROM final_calculations