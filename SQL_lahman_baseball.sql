-- 1. What range of years for baseball games played does the provided database cover?

-- ANSWER:  1871 to 2016
SELECT MIN(yearid),MAX(yearid)
FROM teams;


-- 2. Find the name and height of the shortest player in the database. 
-- How many games did he play in? What is the name of the team for which he played? 

--  ANSWER:  Eddie Gaedel at 43 inches.
SELECT playerid,teamid,namefirst,namelast,height,g_all
FROM people
LEFT JOIN appearances USING (playerid) 
where playerid = 'gaedeed01'
ORDER BY height ASC;

-- ANSWER:  1 game, Baltimore Orioles.
SELECT
distinct teamid,name
FROM teams
LEFT JOIN teamsfranchises USING (franchid)
WHERE teamid = 'SLA';


-- 3. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?

-- ANSWER:  David Price.
WITH vandy_players AS (SELECT
							DISTINCT playerid,
							namefirst,
							namelast
						FROM collegeplaying
						INNER JOIN schools USING(schoolid)
						INNER JOIN people USING(playerid)
						WHERE schoolid LIKE 'vandy')SELECT
	namefirst,
	namelast,
	SUM(salary)::numeric::money AS total_salary
FROM vandy_players
INNER JOIN salaries USING(playerid)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC;


-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.

SELECT
CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = 'SS' THEN 'Infield'
	WHEN pos = '1B' THEN 'Infield'
	WHEN pos = '2B' THEN 'Infield'
	WHEN pos = '3B' THEN 'Infield'
	WHEN pos = 'P' THEN 'Battery'
	WHEN pos = 'C' THEN 'Battery' END AS positions,
	sum(po)
FROM fielding
WHERE yearid = '2016'
GROUP BY positions;


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT CONCAT(LEFT(yearid::text, 3),'0s') AS decade, ROUND(AVG (so),2) AS avg_strikeout, ROUND(AVG (hr),2) AS avg_homerun
FROM batting
WHERE yearid >= 1920
GROUP BY decade


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT
playerid,sb::numeric AS stolen_bases,cs::numeric AS caught_stealing_bases,
(sb+cs)::numeric AS total_attempts, ROUND((sb::numeric/(sb+cs)::numeric)*100,2) as success_percentage
FROM batting
WHERE yearid = '2016' and sb > '19'
ORDER by success_percentage DESC


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? Seattle Mariners

SELECT
name,sum(w) AS sum_of_wins,yearid
FROM teams
WHERE yearid BETWEEN '1970' AND '2016' and lgid NOT LIKE 'UA' and wswin = 'N'
GROUP BY name,yearid
ORDER BY sum_of_wins DESC
LIMIT 1;


-- What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. 
-- ANSWER:  LA Dodgers, 83.  It was because there was a player's strike.

SELECT
sum(w) AS sum_of_wins,yearid
FROM teams
WHERE yearid BETWEEN '1970' AND '2016' AND yearid <> 1981 and lgid NOT LIKE 'UA' and wswin = 'Y'
GROUP BY name,yearid
ORDER BY sum_of_wins ASC
LIMIT 1;


-- Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
-- What percentage of the time? 3.8%

WITH most_win_by_year AS
	(SELECT yearid, max(w) AS most_wins
	FROM teams
	WHERE yearid >= 1970
	GROUP BY yearid
	ORDER BY yearid)SELECT COUNT(DISTINCT most_win_by_year.yearid) AS WS_and_most_wins,
	MAX(most_win_by_year.yearid)- MIN(most_win_by_year.yearid) AS total_years,
	ROUND(100*(COUNT(DISTINCT most_win_by_year.yearid::numeric))
	/(MAX(most_win_by_year.yearid::numeric)- MIN(most_win_by_year.yearid::numeric)),2) AS Percentage
FROM most_win_by_year
LEFT JOIN teams
ON (teams.yearid = most_win_by_year.yearid AND most_wins = w)
WHERE most_win_by_year.yearid >= 1970
	AND wswin = 'Y';


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). 

-- Only consider parks where there were at least 10 games played. 
-- Report the park name, team name, and average attendance. 
-- Repeat for the lowest 5 average attendance.

SELECT
team,park,ROUND(avg(attendance),0) as avg_att
FROM homegames
WHERE year = '2016' and games > '9'
GROUP BY year, team, park
ORDER BY avg_att ASC
LIMIT 5;

SELECT
team,park,ROUND(avg(attendance),0) as avg_att
FROM homegames
WHERE year = '2016' and games > '9'
GROUP BY year, team, park
ORDER BY avg_att ASC
LIMIT 5;


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

SELECT
	CONCAT(namefirst, ' ', namelast) AS micro_managers,
	yearid AS year,
	name AS team_name,
	awardid AS award,
	awardsmanagers.lgid
FROM awardsmanagers
INNER JOIN managers USING(playerid, yearid)
INNER JOIN people USING(playerid)
INNER JOIN teams USING(teamid, yearid)
WHERE playerid IN (SELECT playerid
					FROM awardsmanagers
					INNER JOIN managers USING(playerid, yearid)
					WHERE awardid LIKE 'TSN%'
						AND awardsmanagers.lgid IN ('AL','NL')
					GROUP BY playerid
					HAVING COUNT(DISTINCT awardsmanagers.lgid) = 2)
AND awardid LIKE 'TSN%'
ORDER BY yearid;


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

WITH maxhr AS
	(SELECT playerid, MAX(hr) AS mosthr
	FROM batting
	GROUP BY playerid),
	firstyear AS
	(SELECT playerid, MIN (yearid) AS firstyear
	FROM appearances
	GROUP BY playerid)
SELECT namefirst, namelast, maxhr.playerid, mosthr
FROM maxhr
LEFT JOIN batting
ON maxhr.playerid = batting.playerid AND mosthr = batting. hr
LEFT JOIN firstyear
ON maxhr.playerid = firstyear.playerid
LEFT JOIN people
ON people.playerid = maxhr.playerid
WHERE (yearid = 2016 AND hr > 0 AND firstyear > 2006)
ORDER BY mosthr DESC;


-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

--After viewing the win rank vs pay rank as a scatterplot, this is only a weak relationship between team salary and numbers of wins each season. A team's odds of winning appear slighlty higher if they are paid more but there are plenty of outlier performances from low paid teams that do well or high paid teams that do poorly.

WITH teamsalary AS
	(SELECT yearid, teamid, sum(salary::numeric::money) as teampay
	FROM salaries
	WHERE yearid >= 2000
	GROUP BY yearid, teamid
	ORDER BY yearid, teamid)
SELECT name, teams.yearid, sum(w) AS year_wins, teampay, RANK()OVER(PARTITION BY teams.yearid ORDER BY SUM(w) DESC) AS winrank, RANK()OVER(PARTITION BY teams.yearid ORDER BY teampay DESC) AS payrank
FROM teams
LEFT JOIN teamsalary
ON teams.teamid = teamsalary.teamid AND teams.yearid = teamsalary.yearid
WHERE teams.yearid >=2000
GROUP BY name, teams.yearid, teampay
ORDER BY name, teams.yearid;


-- 12. In this question, you will explore the connection between number of wins and attendance.
--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>
--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>

-- Does there appear to be any correlation between attendance at home games and number of wins?
	
WITH ws_attendance AS (SELECT
							name,
							wswin,
							homegames.attendance,
							year
						FROM teams
						INNER JOIN homegames ON team = teamid AND year = yearid
						WHERE wswin IS NOT NULL
							AND homegames.attendance > 0)
	
SELECT
	SUM(CASE WHEN wsA1.wswin = 'Y' AND wsA1.attendance < wsA2.attendance THEN 1 END) AS win_with_increase,                          -- 57
    SUM(CASE WHEN wsA1.wswin = 'Y' AND wsA1.attendance >= wsA2.attendance THEN 1 END) AS win_and_no_increase                        -- 56
FROM ws_attendance AS wsA1
INNER JOIN ws_attendance AS wsA2 USING (name)
WHERE wsA1.year +1 = wsA2.year;

WITH average_win_2000s AS (SELECT
								teamid,
								name,
								ROUND(AVG(w),2) AS average_wins
							FROM teams
							WHERE yearid BETWEEN 2000 AND 2009
						    GROUP BY teamid, name)SELECT
	name,
	COUNT(teamid) AS above_averageg_seasons,
	ROUND(AVG(w),2)
FROM average_win_2000s
INNER JOIN teams USING (teamid, name)
WHERE yearid >= 2010
	AND w > average_wins
GROUP BY name
ORDER BY above_averageg_seasons DESC;


-- when there was more than 100 games in a season

SELECT
	DISTINCT playerid
FROM batting
WHERE g > 100;


-- all players with more than 100 games played

SELECT
	playerid,
	COUNT(playerid)
FROM batting
GROUP BY playerid
HAVING SUM(g) > 100;


-- Do teams that win the world series see a boost in attendance the following year?
-- What about teams that made the playoffs?
-- Making the playoffs means either being a division winner or a wild card winner

SELECT
	managers.yearid,
	name, managers.w,
	attendance
FROM managers
INNER JOIN teams USING (teamid, yearid)
WHERE playerid = 'johnsda02'
GROUP BY managers.yearid, name, managers.w, attendance
ORDER BY managers.yearid;


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. 
-- Investigate this claim and present evidence to either support or dispute this claim. 

-- First, determine just how rare left-handed pitchers are compared with right-handed pitchers. 

SELECT
  ROUND(100.0 * sum(case when throws = 'L' then 1 else 0 end) 
  /
  count(throws),2) AS lefties_percentage
FROM people;


-- Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

SELECT
SUM(CASE when throws = 'L' then 1 else 0 end) AS lefties,
SUM(CASE when throws = 'R' then 1 else 0 end) AS righties
FROM people
LEFT JOIN awardsplayers USING (playerid)
WHERE awardid = 'Cy Young Award';


-- BONUS--------------------------------------------------------------------------------------------------
-- 1. In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

-- a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.

SELECT DISTINCT lgid, max(w)
FROM teams t
WHERE yearid = 2016
GROUP BY lgid;


-- If you need a hint, you can structure your query as follows:

-- SELECT DISTINCT lgid, ( <Write a correlated subquery here that will pull the teamid for the team with the highest number of wins from each league> )
-- FROM teams t
-- WHERE yearid = 2016;

-- b. One downside to using correlated subqueries is that you can only return exactly one row and one column. This means, for example that if we wanted to pull in not just the teamid but also the number of wins, we couldn't do so using just a single subquery. (Try it and see the error you get). Add another correlated subquery to your query on the previous part so that your result shows not just the teamid but also the number of wins by that team.

-- c. If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.

SELECT DISTINCT ON (lgid) lgid, teamid, w
FROM teams
WHERE yearid = 2016
ORDER BY lgid,w DESC;
	
SELECT DISTINCT lgid, max(w)
FROM teams t
WHERE yearid = 2016
GROUP BY lgid;

(SELECT lgid,teamid,w
FROM teams
WHERE yearid = 2016 AND lgid = 'AL'
ORDER BY w DESC
LIMIT 1)
UNION
(SELECT lgid,teamid,w
FROM teams
WHERE yearid = 2016 AND lgid = 'NL'
ORDER BY w DESC
LIMIT 1);

-- d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword (https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016. 

-- If you want a hint, you can structure your query as follows:

-- SELECT *
-- FROM (SELECT DISTINCT lgid 
-- 	  FROM teams
-- 	  WHERE yearid = 2016) AS leagues,
-- 	  LATERAL ( <Fill in a subquery here to retrieve the teamid and number of wins> ) as top_teams;

SELECT *
FROM (SELECT DISTINCT lgid 
	  FROM teams
	  WHERE yearid = 2016) AS leagues,
	  LATERAL (SELECT lgid,teamid,w
FROM teams
WHERE yearid = 2016 AND lgid = 'AL') as top_teams;


-- e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. (Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.

