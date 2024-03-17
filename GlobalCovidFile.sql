--Displaying Key Data by Location and Date
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent is NOT NULL
ORDER BY 1,2;

--Total Cases vs Total Deaths in the US
--Shows likelihood of dying if you contract covid in US
SELECT location, date, total_cases, total_deaths, (total_deaths::FLOAT / total_cases) * 100.0 as DeathPercentage
FROM covid_deaths
WHERE location ilike '%united states'
AND continent is NOT NULL
ORDER BY 1,2;

--Total Cases vs Population
--Shows what percentage of population was infected with covid
SELECT location, date, population, total_cases, (total_cases::FLOAT / population) * 100.0 as InfectionRate
FROM covid_deaths
-- WHERE location ilike '%united states'
WHERE continent is NOT NULL
ORDER BY 1,2;

--Look at countries with highest infection rate
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases::FLOAT / population) * 100.0) as InfectionRate
FROM covid_deaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC NULLS LAST;

--Look at countries with highest infection rate over time
SELECT location, population, date, MAX(total_cases) as HighestInfectionCount, MAX((total_cases::FLOAT / population) * 100.0) as InfectionRate
FROM covid_deaths
GROUP BY location, population, date
ORDER BY InfectionRate DESC NULLS LAST;

--Total Number of Deaths due to Covid-19 by Region / Continent
SELECT continent, SUM(cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE continent is NOT NULL
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY continent
ORDER BY TotalDeathCount DESC NULLS LAST;

--Global Numbers for cases, deaths, and percentage of deaths
SELECT 
SUM(new_cases) AS total_cases,
SUM(new_deaths) AS total_deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN NULL
    ELSE CAST(SUM(new_deaths) as Float) / SUM(new_cases) * 100
END AS total_death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL;


--Total Population v Vaccination with Rolling Vaccination Count
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3;


--CTE showing rolling vaccination percentage
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100.0 AS VaccinationRate
FROM PopvsVac;


--VIEW of rolling vaccinations by location and date
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL;


SELECT * FROM public.percentpopulationvaccinated;







