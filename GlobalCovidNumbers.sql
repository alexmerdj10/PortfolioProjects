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

--Showing countries with highest death count by population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC NULLS LAST;

--Showing continent with highest death count by population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM covid_deaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC NULLS LAST;

--Global Numbers

SELECT 
SUM(new_cases) AS total_cases,
SUM(new_deaths) AS total_deaths,
CASE
	WHEN SUM(new_cases) = 0 THEN NULL
    ELSE CAST(SUM(new_deaths) as Float) / SUM(new_cases) * 100
END AS total_death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL;


--Total Population v Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3;


--CTE

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
SELECT *, (RollingPeopleVaccinated/Population)*100.0
FROM PopvsVac;


--VIEW

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER(Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is NOT NULL;


SELECT * FROM public.percentpopulationvaccinated







