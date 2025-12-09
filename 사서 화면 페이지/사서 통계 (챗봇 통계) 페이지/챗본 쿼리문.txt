INSERT INTO ai_analysis_log (
    lib_id, 
    quest_text, 
    gen_sql, 
    chart_type, 
    error_msg, 
    exec_time
) VALUES (
    'admin01',                                  -- 로그인한 사서 ID
    '컴퓨터공학과에서 가장 많이 빌린 책 Top 5',      -- 자연어 질문
    
    -- [수정됨] 실제 DDL에 맞는 실행 가능한 쿼리
    'SELECT
        T4.bk_title AS 서명,
        T4.bk_auth  AS 저자,
        COUNT(T1.loan_id) AS 대출횟수
    FROM loans T1
    JOIN users T2 ON T1.usr_id = T2.usr_id
    JOIN book_copies T3 ON T1.cbk_id = T3.cbk_id
    JOIN books T4 ON T3.bk_id = T4.bk_id
    WHERE T2.usr_dept = "컴퓨터공학과"
    GROUP BY T4.bk_id, T4.bk_title, T4.bk_auth
    ORDER BY 대출횟수 DESC
    LIMIT 5;', 
    
    'bar',   -- 차트 타입
    NULL,    -- 에러 메시지 없음
    120      -- 실행 시간 (ms)
);
