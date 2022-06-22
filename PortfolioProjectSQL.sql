SELECT *
FROM PortfolioProject..CovidDeaths
order by 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
order by 3,4

-- Select data that we will use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- looking at total cases vs total deaths in united states
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
order by 1,2

-- looking at total cases vs total deaths in united kingdom
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'
order by 1,2

-- looking at total cases vs population
-- percentage of population that got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'
order by 1,2

-- Looking at countries with highest infection percentage of its population ***
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
order by PercentPopulationInfected desc

-- Looking at countries with highest infection percentage of its population ****
SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population, date
order by PercentPopulationInfected desc

-- countries with the highest death count per population
-- converting total death to int 
SELECT  location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
order by TotalDeathCount desc

-- countries with the highest death count per continent
-- converting total death to int 
SELECT  location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
AND location NOT LIKE '%income%'
AND location not in ('World', 'European Union', 'International')
GROUP BY location
order by TotalDeathCount desc

-- OTHER WAY
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS, death percentage over time
-- new cases is a float while new deaths is in varchar so we have to cast it
SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
order by 1,2

-- World general statistic on total cases/deaths *
SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
order by 1,2


-- Joining tables together
SELECT *
FROM PortfolioProject..C ovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- Looking at total people in the world who have been vaccinated (Total population vs new vaccinations)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Rolling count of vaccinations per location
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- USE CTE
-- Can't do calculation on a created name so create a CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccination
CREATE TABLE #PercentPopulationVaccination
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccination


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

CREATE VIEW InfectedPercentageUK as
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'


SELECT * 
FROM PercentPopulationVaccinated

-- Total deaths per continent **
SELECT location AS continent, SUM(CAST(new_deaths as int)) AS TotalDeath
FROM PortfolioProject..CovidDeaths
WHERE continent is null
AND location NOT LIKE '%income%'
AND location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeath desc


