Covid-19 SQL

-- Displaying total cases, deaths, and population by location and date
SELECT
  location,
  date,
  total_cases,
  new_cases,
  total_deaths,
  population
FROM
  covid_deaths
WHERE
  continent IS NOT NULL
ORDER BY
  location, date;



-- Calculating death percentage among confirmed cases in the United States
SELECT
  location,
  date,
  total_cases,
  total_deaths,
  (total_deaths::FLOAT / total_cases) * 100.0 AS death_percentage
FROM
  covid_deaths
WHERE
  location ILIKE '%united states%'
  AND continent IS NOT NULL
ORDER BY
  location, date;



-- Calculating infection rate as a percentage of population
SELECT
  location,
  date,
  population,
  total_cases,
  (total_cases::FLOAT / population) * 100.0 AS infection_rate
FROM
  covid_deaths
WHERE
  continent IS NOT NULL
ORDER BY
  location, date;



-- Identifying countries with the highest overall infection rate
SELECT
  location,
  population,
  MAX(total_cases) AS highest_infection_count,
  MAX((total_cases::FLOAT / population) * 100.0) AS infection_rate
FROM
  covid_deaths
WHERE
  continent IS NOT NULL
GROUP BY
  location,
  population
ORDER BY
  infection_rate DESC NULLS LAST;



-- Tracking the highest infection rate by country over time
SELECT
  location,
  population,
  date,
  MAX(total_cases) AS highest_infection_count,
  MAX((total_cases::FLOAT / population) * 100.0) AS infection_rate
FROM
  covid_deaths
GROUP BY
  location,
  population,
  date
ORDER BY
  infection_rate DESC NULLS LAST;



-- Summing total Covid-19 deaths by continent
SELECT
  continent,
  SUM(CAST(total_deaths AS INT)) AS total_death_count
FROM
  covid_deaths
WHERE
  continent IS NOT NULL
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY
  continent
ORDER BY
  total_death_count DESC NULLS LAST;



-- Summing global Covid-19 cases, deaths, and calculating global death percentage
SELECT
  SUM(new_cases) AS total_cases,
  SUM(new_deaths) AS total_deaths,
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE CAST(SUM(new_deaths) AS FLOAT) / SUM(new_cases) * 100
  END AS total_death_percentage
FROM
  covid_deaths
WHERE
  continent IS NOT NULL;



-- Calculating rolling vaccination totals by country and date
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (
    PARTITION BY dea.location
    ORDER BY dea.location, dea.date
  ) AS rolling_people_vaccinated
FROM
  covid_deaths dea
JOIN
  covid_vaccinations vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL
ORDER BY
  dea.location, dea.date;



-- Calculating rolling vaccination percentage using a CTE
WITH pop_vs_vac AS (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
      PARTITION BY dea.location
      ORDER BY dea.location, dea.date
    ) AS rolling_people_vaccinated
  FROM
    covid_deaths dea
  JOIN
    covid_vaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
)
SELECT
  *,
  (rolling_people_vaccinated / population) * 100.0 AS vaccination_rate
FROM
  pop_vs_vac;



-- Creating a view to show rolling vaccination totals by location and date
CREATE VIEW percent_population_vaccinated AS
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(vac.new_vaccinations) OVER (
    PARTITION BY dea.location
    ORDER BY dea.location, dea.date
  ) AS rolling_people_vaccinated
FROM
  covid_deaths dea
JOIN
  covid_vaccinations vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL;



-- Previewing the created view
SELECT
  *
FROM
  public.percent_population_vaccinated;
