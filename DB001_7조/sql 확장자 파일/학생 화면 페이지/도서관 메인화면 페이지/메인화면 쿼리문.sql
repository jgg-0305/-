USE library_system;
-- -----------------------------------------------------
-- 1. [헤더] 로그인 사용자 정보 조회
-- -----------------------------------------------------
SELECT 
    usr_name, 
    usr_stat  -- (정상/정지/졸업)
FROM 
    users 
WHERE 
    usr_id = 20233849; -- [변수] 로그인한 사용자 ID


-- -----------------------------------------------------
-- 2. [대시보드] 도서관 현황 통계 (한 번에 조회)
-- -----------------------------------------------------
-- 용도: 메인 화면의 숫자 데이터 바인딩 (장서수, 이용자수, 좌석현황)
SELECT
    -- (1) 총 장서 수 (실물 + 전자책 포함 모든 복본)
    (SELECT COUNT(*) FROM book_copies) AS val_total_books,
    
    -- (2) 전자책 수 (is_ebook = TRUE)
    (SELECT COUNT(*) FROM book_copies WHERE is_ebook = 1) AS val_ebooks,
    
    -- (3) 현재 도서관 이용자 수 (추정치: 최근 3시간 내 '입실' 기록 수)
    -- * DDL log_type ENUM: '입실', '퇴실'
    (SELECT COUNT(DISTINCT usr_id) 
     FROM entry_logs 
     WHERE log_time >= DATE_SUB(NOW(), INTERVAL 3 HOUR) 
       AND log_type = '입실') AS val_current_users,
       
    -- (4) 열람실 전체 좌석 수
    (SELECT COUNT(*) FROM seats) AS val_total_seats,
    
    -- (5) 사용 중인 좌석 수
    -- * DDL seat_stat ENUM: '사용가능', '사용중', '수리중'
    (SELECT COUNT(*) FROM seats WHERE seat_stat = '사용중') AS val_occupied_seats;


-- -----------------------------------------------------
-- 3. [공지사항] 최신 공지 목록 (Top 3)
-- -----------------------------------------------------
SELECT 
    ntc_id,
    ntc_title, 
    DATE_FORMAT(ntc_date, '%m.%d') AS ntc_date_fmt -- 예: 12.09
FROM 
    notices
ORDER BY 
    ntc_important DESC, -- 필독 공지 우선
    ntc_date DESC, 
    ntc_id DESC
LIMIT 3;


-- -----------------------------------------------------
-- 4. [인기 도서] 이달의 베스트셀러 Top 5
-- -----------------------------------------------------
-- 조건: monthly_book_stats 테이블 활용 (성능 최적화)
SELECT 
    T1.bk_id,
    T1.bk_title,    -- 책 제목
    T1.bk_auth,     -- 저자
    T1.bk_image     -- 표지 이미지
FROM 
    books T1
JOIN 
    monthly_book_stats T2 ON T1.bk_id = T2.bk_id
WHERE 
    T2.stat_year = YEAR(CURDATE()) 
    AND T2.stat_month = MONTH(CURDATE())
ORDER BY 
    T2.loan_cnt DESC
LIMIT 5;


-- -----------------------------------------------------
-- 5. [신착 도서] 새로 들어온 책 Top 5
-- -----------------------------------------------------
-- 복본(book_copies)의 등록일(cbk_reg) 기준 최신순
SELECT 
    B.bk_id,
    B.bk_title,
    B.bk_auth,
    B.bk_image,
    MAX(C.cbk_reg) AS recent_reg_date
FROM 
    books B
JOIN 
    book_copies C ON B.bk_id = C.bk_id
GROUP BY 
    B.bk_id
ORDER BY 
    recent_reg_date DESC
LIMIT 5;


-- -----------------------------------------------------
-- 6. [검색] 도서 통합 검색 (메인 배너)
-- -----------------------------------------------------
SELECT 
    bk_id,
    bk_title,
    bk_auth,
    bk_pub,
    bk_year,
    bk_image
FROM 
    books
WHERE 
    bk_title LIKE CONCAT('%', '데이터 사이언스 입문', '%')   -- [변수] 검색어
    OR bk_auth LIKE CONCAT('%', '김진,최정아', '%') -- [변수] 검색어
ORDER BY 
    bk_title ASC
LIMIT 10;


-- -----------------------------------------------------
-- 7. [로그] 접속 기록 (방문자 집계용)
-- -----------------------------------------------------
INSERT INTO entry_logs (
    usr_id, 
    log_type, 
    log_time
) VALUES (
    20233849,       -- [변수] 사용자 ID
    '입실',   -- DDL ENUM 값 준수
    NOW()
);