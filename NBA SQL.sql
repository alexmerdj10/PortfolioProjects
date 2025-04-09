NBA SQL

Query #1 -- Analyzing the best, worst, and average offensive rating (points per 100 possessions) for each NBA season and calculating year-over-year improvement

WITH season_stats AS (
    SELECT team, pts_per_100_poss, season
    FROM "Team Stats Per 100 Poss"
)
SELECT 
    season,
    MAX(pts_per_100_poss) AS best_offense,
    MIN(pts_per_100_poss) AS worst_offense,
	ROUND(AVG(pts_per_100_poss)) AS avg_offense,
	ROUND(AVG(pts_per_100_poss) - LAG(AVG(pts_per_100_poss)) OVER (ORDER BY season)) AS rate_of_improvement
FROM 
     season_stats
GROUP BY 
     season
ORDER BY 
     season;




Query #2 -- Classifying NBA players by draft era and identifying the top 10 colleges producing the most players per era

WITH player_era AS (
    SELECT
        pd.colleges,
        pd.id,
        CASE 
            WHEN pd.from BETWEEN '1980' AND '1994' THEN 'Classic'
            WHEN pd.from BETWEEN '1995' AND '2013' THEN 'Transitional'
            WHEN pd.from BETWEEN '2014' AND '2025' THEN 'Modern'
        END AS era_drafted
    FROM 
	"Player Directory" pd
    WHERE 
	pd.colleges IS NOT NULL
),
college_counts AS (
    SELECT
        era_drafted,
        colleges,
        COUNT(id) AS n_players,
        RANK() OVER (PARTITION BY era_drafted ORDER BY COUNT(id) DESC) AS rank
    FROM player_era
    GROUP BY era_drafted, colleges
)
SELECT
    era_drafted,
    colleges,
    n_players,
    rank
FROM 
     college_counts
WHERE 
     rank <= 10
     AND era_drafted IS NOT NULL
ORDER BY 
     era_drafted, rank;




Query #3 -- Calculating a weighted composite score for individual player seasons since 2014 to determine the best overall statistical performances in the modern era

SELECT 
    player_id,
    player,
    season,
    (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) AS composite_score
FROM 
    "Advanced"
WHERE 
    lg = 'NBA' AND
    bpm IS NOT NULL AND usg_percent IS NOT NULL AND ts_percent IS NOT NULL AND ws IS NOT NULL AND vorp IS NOT NULL AND per IS NOT NULL
    AND g > 50
    AND season >= 2014
ORDER BY 
    composite_score DESC;




Query #4 -- Ranking players within each era (Classic, Transitional, Modern) based on their composite season score using advanced metrics

WITH ranked_seasons AS (
    SELECT 
        player_id,
        player,
        season,
        (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) AS composite_score,
        CASE 
            WHEN season BETWEEN 1980 AND 1994 THEN 'classic'
            WHEN season BETWEEN 1995 AND 2013 THEN 'transitional'
            WHEN season BETWEEN 2014 AND 2025 THEN 'modern'
            ELSE 'other'
        END AS era,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                          WHEN season BETWEEN 1980 AND 1994 THEN 'classic'
                                          WHEN season BETWEEN 1995 AND 2013 THEN 'transitional'
                                          WHEN season BETWEEN 2014 AND 2025 THEN 'modern'
                                          ELSE 'other'
                                        END
                           ORDER BY (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) DESC) AS rank
    FROM 
        "Advanced"
    WHERE 
        lg = 'NBA' 
        AND bpm IS NOT NULL 
        AND usg_percent IS NOT NULL 
        AND ts_percent IS NOT NULL 
        AND ws IS NOT NULL 
        AND vorp IS NOT NULL 
        AND per IS NOT NULL
        AND g > 50
        AND season >= 1980
)
SELECT 
    player_id,
    player,
    season,
    composite_score,
    era
FROM ranked_seasons
WHERE rank <= 5
ORDER BY era, rank;




Query #5 -- -- Identifying the top 10 players each season since 2025 by calculating a composite performance score from advanced metrics

WITH season_leaders AS (
    SELECT 
        player_id,
        player,
        season,
        (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) AS composite_score,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) DESC
        ) AS rank
    FROM 
        "Advanced"
    WHERE 
        lg = 'NBA'
        AND bpm IS NOT NULL 
        AND usg_percent IS NOT NULL 
        AND ts_percent IS NOT NULL 
        AND ws IS NOT NULL 
        AND vorp IS NOT NULL 
        AND per IS NOT NULL
        AND g > 50
        AND season >= 2025
)
SELECT 
    player,
    season,
    composite_score
FROM season_leaders
WHERE rank <=10
ORDER BY season;



Query #6 -- Ranking the top 3 players per season since 2021 based on a composite score to highlight elite individual performances

WITH season_leaders AS (
    SELECT 
        player_id,
        player,
        season,
        (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) AS composite_score,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) DESC
        ) AS rank
    FROM 
        "Advanced"
    WHERE 
        lg = 'NBA'
        AND bpm IS NOT NULL 
        AND usg_percent IS NOT NULL 
        AND ts_percent IS NOT NULL 
        AND ws IS NOT NULL 
        AND vorp IS NOT NULL 
        AND per IS NOT NULL
        AND g > 50
        AND season > 2020
)
SELECT 
    player,
    season,
    composite_score,
    rank
FROM season_leaders
WHERE rank <=3
ORDER BY season;




Query #7 -- Evaluating Jamal Murray’s best NBA season by calculating and ranking his composite score across all qualifying years

SELECT 
    player,
    season,
    (0.284 * bpm) + 
    (0.001 * ts_percent) + 
    (0.122 * ws) + 
    (0.092 * usg_percent) + 
    (0.220 * per) + 
    (0.282 * vorp) AS composite_score
FROM 
    "Advanced"
WHERE 
    lg = 'NBA'
    AND player = 'Jamal Murray'
    AND bpm IS NOT NULL
    AND usg_percent IS NOT NULL
    AND ts_percent IS NOT NULL
    AND ws IS NOT NULL
    AND vorp IS NOT NULL
    AND per IS NOT NULL
    AND g > 50
ORDER BY 
    composite_score DESC;




Query #8 -- Comparing the top composite score player to the official MVP winner each season since 2014 and checking if they match

WITH season_leaders AS (
    SELECT 
        player_id,
        player,
        season,
        (0.284 * bpm) + 
        (0.001 * ts_percent) + 
        (0.122 * ws) + 
        (0.092 * usg_percent) + 
        (0.220 * per) + 
        (0.282 * vorp) AS composite_score,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY (0.284 * bpm) + (0.001 * ts_percent) + (0.122 * ws) + 
                     (0.092 * usg_percent) + (0.220 * per) + (0.282 * vorp) DESC
        ) AS rank
    FROM 
        "Advanced"
    WHERE 
        lg = 'NBA'
        AND bpm IS NOT NULL 
        AND usg_percent IS NOT NULL 
        AND ts_percent IS NOT NULL 
        AND ws IS NOT NULL 
        AND vorp IS NOT NULL 
        AND per IS NOT NULL
        AND g > 50
        AND season >= 2014
),
mvp_winners AS (
    SELECT 
        player AS mvp_player,
        season AS mvp_season
    FROM 
        "Player Award Shares"
    WHERE 
        award ILIKE '%mvp%'
        AND winner = 'true'
)
SELECT 
    sl.season,
    sl.player AS top_composite_player,
    sl.composite_score,
    mw.mvp_player,
    sl.rank,
    CASE 
        WHEN mw.mvp_player IS NULL THEN NULL
        WHEN sl.player = mw.mvp_player THEN TRUE
        ELSE FALSE
    END AS match,
    CASE 
        WHEN mw.mvp_player IS NULL THEN NULL
        WHEN sl.player = mw.mvp_player THEN 'Matched'
        ELSE 'Missed'
    END AS match_status,
    CASE 
        WHEN mw.mvp_player IS NULL THEN NULL
        WHEN sl.player = mw.mvp_player THEN 1
        ELSE 0
    END AS match_flag
FROM 
    season_leaders sl
LEFT JOIN 
    mvp_winners mw
    ON sl.season = mw.mvp_season
WHERE 
    sl.rank <= 2
ORDER BY 
    sl.season, sl.rank;
