Select *
From PortfolioProject..covidDeaths$
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..covidDeaths$
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..covidDeaths$
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..covidDeaths$
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..covidDeaths$
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--Showing Continents with Highest Death Count Per Population 

Select location, MAX(CAST(total_deaths as int)) as TotalDeathCount -- MAX((total_deaths/population)) * 100 as PercentDeathCOunt
from PortfolioProject..covidDeaths$
where continent is null and location NOT IN ('World', 'International')
group by location, population
order by TotalDeathCount desc

-- GLOBAL NUMBERS

--Looking for total cases and total deaths in a perticular day globally.
Select date,  SUM(new_cases) as totalCases, SUM(CAST(new_deaths as int)) as totalDeaths, (SUM(CAST(new_deaths as int))/SUM(new_cases)) * 100 as PercentDeath
From PortfolioProject..covidDeaths$
Where continent is not null
GROUP BY date
order by 2 desc


-- Looking at total population vs total vaccination

select d.location as country, MAX(d.population) as population, sum(new_cases) as TotalCases, sum(CAST(new_vaccinations as int)) as totalVaccination, sum(CAST(new_vaccinations as int))/MAX(d.population) * 100 as PercentVaccination
from PortfolioProject..covidDeaths$ as d
join PortfolioProject..covidVaccination$ as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
group by d.location
order by country

--USE CTE
--Looking at the rolling increase in vaccination with country and date
with PopvsVac (country, date, population, new_vacinations, rollingVaccinations) 
as(
select d.location as country, d.date, d.population--, MAX(d.population) as population, sum(new_cases) as TotalCases, sum(CONVERT(int, new_vaccinations)) as totalVaccination,
--sum(CAST(new_vaccinations as int))/MAX(d.population) * 100 as PercentVaccination
,(cast(v.new_vaccinations as int)) as new_vaccinations ,sum(CAST(new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rollingVaccinations
from PortfolioProject..covidDeaths$ as d
join PortfolioProject..covidVaccination$ as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null)
--group by d.location)
select *, rollingVaccinations/population * 100 percentVaccinated
from PopvsVac


--TEMP Table

DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
d.location as country, 
d.date, 
d.population,
(cast(v.new_vaccinations as int)) as new_vaccinations,
sum(CAST(new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rollingVaccinations

from PortfolioProject..covidDeaths$ as d
join PortfolioProject..covidVaccination$ as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null
--group by d.location)

select *, rolling_vaccinations/population * 100 percentVaccinated
from  #PercentPopulationVaccinated

--Creating view to store data for later visualization

CREATE view percentPopulationVaccinated as
SELECT 
d.location as country, 
d.date, 
d.population,
(cast(v.new_vaccinations as int)) as new_vaccinations,
sum(CAST(new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as rollingVaccinations

from PortfolioProject..covidDeaths$ as d
join PortfolioProject..covidVaccination$ as v
	on d.location = v.location
	and d.date = v.date
where d.continent is not null

select * 
from percentPopulationVaccinated