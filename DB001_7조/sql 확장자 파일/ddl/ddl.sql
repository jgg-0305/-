DROP DATABASE IF EXISTS library_system;
CREATE DATABASE library_system DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE library_system;

-- -----------------------------------------------------
-- 1. 기초 정보 (장르, 위치, 사용자, 사서)
-- -----------------------------------------------------

-- 1.1 장르 (카테고리)
CREATE TABLE genres (
    gnr_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '장르 고유 ID',
    gnr_name VARCHAR(50) NOT NULL UNIQUE COMMENT '장르명',
    parent_gnr_id INT COMMENT '상위 장르 ID (NULL이면 최상위)',
    
    INDEX idx_parent_gnr_id (parent_gnr_id),
    CONSTRAINT fk_genres_parent FOREIGN KEY (parent_gnr_id)
        REFERENCES genres (gnr_id) ON DELETE SET NULL
) COMMENT '도서 장르 및 분류 체계';

-- 1.2 자료실 위치
CREATE TABLE locations (
    loc_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '위치 ID',
    loc_flr INT NOT NULL COMMENT '층수',
    loc_name VARCHAR(50) NOT NULL UNIQUE COMMENT '자료실명',
    loc_class VARCHAR(50) COMMENT '청구기호 분류 (문자열)'
) COMMENT '도서관 내 자료실 위치 정보';
-- 1.3 사용자 (학생/교직원)
CREATE TABLE users (
    usr_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '사용자 ID (학번 등)',
    usr_name VARCHAR(50) NOT NULL COMMENT '이름',
    usr_dept VARCHAR(50) COMMENT '학과 (전공)',
    usr_phone VARCHAR(20) UNIQUE COMMENT '연락처',
    usr_lcnt TINYINT DEFAULT 0 COMMENT '현재 대출 권수',
    usr_gender ENUM('남', '여') NOT NULL COMMENT '성별', 
    -- 상태 (정상, 정지, 졸업)
    usr_stat ENUM('정상', '정지', '졸업') NOT NULL DEFAULT '정상' COMMENT '상태',
    usr_enrl BOOLEAN NOT NULL COMMENT '재학 여부',
    
    INDEX idx_usr_name (usr_name),
    INDEX idx_usr_stat (usr_stat)
) COMMENT '도서관 이용자 정보';


-- 1.4 사서 (관리자)
CREATE TABLE librarians (
    lib_id VARCHAR(30) NOT NULL PRIMARY KEY COMMENT '사서 ID',
    lib_pw VARCHAR(255) NOT NULL COMMENT '비밀번호',
    lib_name VARCHAR(50) NOT NULL COMMENT '이름',
    lib_phone VARCHAR(20) COMMENT '연락처',
    lib_role VARCHAR(20) COMMENT '직책',
    
    -- 자격 등급
    lib_lic ENUM( '준사서', '2급정사서', '1급정사서') NOT NULL COMMENT '자격 등급'
) COMMENT '도서관 관리자 정보';


-- -----------------------------------------------------
-- 2. 도서 및 실물 관리
-- -----------------------------------------------------

-- 2.1 도서 서지 정보
CREATE TABLE books (
    bk_id VARCHAR(50) NOT NULL PRIMARY KEY COMMENT '도서 청구기호 (ID)',
    gnr_id INT NOT NULL COMMENT '장르 ID',
    bk_isbn VARCHAR(20) NOT NULL UNIQUE COMMENT 'ISBN',
    bk_title VARCHAR(200) NOT NULL COMMENT '도서명',
    bk_auth VARCHAR(100) COMMENT '저자',
    bk_pub VARCHAR(100) COMMENT '출판사',
    bk_year YEAR COMMENT '출판 연도',
    bk_image VARCHAR(255) COMMENT '표지 이미지',
    bk_intro TEXT COMMENT '책 소개',
    
    INDEX idx_bk_title (bk_title),
    INDEX idx_bk_auth (bk_auth),
    
    CONSTRAINT fk_books_genres FOREIGN KEY (gnr_id)
        REFERENCES genres (gnr_id) ON DELETE RESTRICT
) COMMENT '도서 서지 정보 (메타데이터)';

-- 2.2 실물 도서 (복본)
CREATE TABLE book_copies (
    cbk_id VARCHAR(60) NOT NULL PRIMARY KEY COMMENT '도서 등록번호 (바코드)',
    bk_id VARCHAR(50) NOT NULL COMMENT '청구기호 (FK)',
    loc_id INT NOT NULL COMMENT '소장 위치 (FK)',
    cbk_vol INT NOT NULL COMMENT '복본 번호',
    is_ebook BOOLEAN NOT NULL DEFAULT FALSE COMMENT '전자책 여부',
    
    -- 상태 (대출가능, 대출중, 분실, 파손)
    cbk_stat ENUM('대출가능', '대출중', '분실', '파손') NOT NULL DEFAULT '대출가능' COMMENT '상태',
    cbk_reg DATE NOT NULL COMMENT '등록일',
    
    UNIQUE KEY uk_book_vol (bk_id, cbk_vol),
    INDEX idx_cbk_stat (cbk_stat),
    CONSTRAINT fk_book_copies_books FOREIGN KEY (bk_id)
        REFERENCES books (bk_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_copies_locations FOREIGN KEY (loc_id)
        REFERENCES locations (loc_id) ON DELETE RESTRICT
) COMMENT '실제 비치된 도서 및 전자책 정보';


-- -----------------------------------------------------
-- 3. 대출/반납 및 제재
-- -----------------------------------------------------

-- 3.1 대출 기록
CREATE TABLE loans (
    loan_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '대출 ID',
    cbk_id VARCHAR(60) NOT NULL COMMENT '도서 등록번호',
    usr_id INT NOT NULL COMMENT '사용자 ID',
    loan_date DATE NOT NULL COMMENT '대출일',
    loan_due DATE NOT NULL COMMENT '반납 예정일',
    loan_ret DATE COMMENT '실제 반납일',
    loan_ext BOOLEAN DEFAULT FALSE COMMENT '연장 여부',
    
    INDEX idx_loan_date (loan_date),
    INDEX idx_loan_due (loan_due),
    CONSTRAINT fk_loans_book_copies FOREIGN KEY (cbk_id)
        REFERENCES book_copies (cbk_id) ON DELETE RESTRICT,
    CONSTRAINT fk_loans_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE RESTRICT
) COMMENT '도서 대출 및 반납 이력';

-- 3.2 패널티 (연체/제재)
CREATE TABLE penalties (
    pnl_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '제재 ID',
    usr_id INT NOT NULL COMMENT '사용자 ID',
    loan_id INT COMMENT '관련 대출 ID (옵션)',
    pnl_type VARCHAR(20) NOT NULL COMMENT '제재 사유 (키워드)',
    
    -- [팀원 피드백 반영] 상세 사유 추가
    pnl_reason VARCHAR(200) COMMENT '제재 상세 사유/비고',
    
    pnl_start DATE NOT NULL COMMENT '시작일',
    pnl_end DATE COMMENT '종료일',
    pnl_actv BOOLEAN NOT NULL DEFAULT TRUE COMMENT '유효 여부',
    
    CONSTRAINT fk_penalties_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE,
    CONSTRAINT fk_penalties_loans FOREIGN KEY (loan_id)
        REFERENCES loans (loan_id) ON DELETE SET NULL
) COMMENT '이용자 제재 내역';


-- -----------------------------------------------------
-- 4. 신청 및 예약
-- -----------------------------------------------------

-- 4.1 도서 예약
CREATE TABLE reservations (
    resv_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '예약 ID',
    usr_id INT NOT NULL COMMENT '사용자 ID',
    bk_id VARCHAR(50) NOT NULL COMMENT '도서 청구기호',
    
    -- [팀원 피드백 반영] 등록번호(복본) 추가 (특정 도서 지정 예약용)
    cbk_id VARCHAR(60) COMMENT '지정된 도서 등록번호 (옵션)',
    
    resv_date DATETIME NOT NULL COMMENT '예약 일시',
    resv_seq INT NOT NULL COMMENT '대기 순번',
    
    -- 상태
    resv_stat ENUM('대기중', '수령가능', '취소됨', '수령완료') NOT NULL DEFAULT '대기중' COMMENT '상태',
    
    UNIQUE KEY uk_resv_book_user (usr_id, bk_id),
    CONSTRAINT fk_reservations_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservations_books FOREIGN KEY (bk_id)
        REFERENCES books (bk_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservations_copies FOREIGN KEY (cbk_id)
        REFERENCES book_copies (cbk_id) ON DELETE SET NULL
) COMMENT '대출 중 도서 예약';

-- 4.2 희망 도서 신청
CREATE TABLE requests (
    req_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '신청 ID',
    usr_id INT NOT NULL COMMENT '신청자 ID',
    req_title VARCHAR(200) NOT NULL COMMENT '도서명',
    req_auth VARCHAR(100) COMMENT '저자',
    req_pub VARCHAR(100) COMMENT '출판사',
    req_year CHAR(4) COMMENT '출판연도 (YYYY)',
    req_isbn VARCHAR(20) COMMENT 'ISBN',
    req_price INT COMMENT '권당 가격',
    req_qty INT NOT NULL DEFAULT 1 COMMENT '신청 권수',
    req_date DATE NOT NULL COMMENT '신청일',
    req_memo VARCHAR(500) NULL COMMENT '신청 사유/비고',
    req_proc_memo VARCHAR(500) NULL COMMENT '반려 사유/비고',
    
    -- 상태
    req_stat ENUM('대기', '승인', '반려', '구매완료') NOT NULL DEFAULT '대기' COMMENT '처리 상태',

    INDEX idx_req_stat (req_stat),
    INDEX idx_req_date (req_date),
    CONSTRAINT fk_requests_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE
) COMMENT '희망 도서 구매 신청';

-- 4.3 상호대차
CREATE TABLE inter_library_loans (
    ill_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '상호대차 ID',
    usr_id INT NOT NULL COMMENT '신청자 ID',
    
    -- [도서 정보]
    ill_title VARCHAR(200) NOT NULL COMMENT '도서명',
    ill_auth VARCHAR(100) COMMENT '저자',
    ill_pub VARCHAR(100) COMMENT '출판사',
    ill_pub_year CHAR(4) COMMENT '출판연도',
    ill_isbn VARCHAR(20) NOT NULL COMMENT 'ISBN',
    ill_lib_name VARCHAR(100) DEFAULT '동의대학교' COMMENT '신청 도서관',
    ill_req_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '신청 일시',
    
    ill_note VARCHAR(255) COMMENT '참고사항 (사용자 입력)',
    -- [팀원 피드백 반영] 관리자 처리 비고 추가
    ill_ans_note VARCHAR(255) COMMENT '처리 내용/관리자 비고',
   
    -- [상태]
    ill_stat ENUM('신청중', '배송중', '도착', '반납완료', '취소됨') NOT NULL DEFAULT '신청중' COMMENT '상태',

    CONSTRAINT fk_ill_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE
) COMMENT '타 대학 도서관 상호대차';


-- -----------------------------------------------------
-- 5. 시설 및 로그
-- -----------------------------------------------------

-- 5.1 열람실 좌석
CREATE TABLE seats (
    seat_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '좌석 고유 ID',
    seat_room ENUM('제1열람실', '제2열람실', '노트북실') NOT NULL COMMENT '열람실 구분',
    seat_num VARCHAR(10) NOT NULL COMMENT '좌석 번호',
    seat_stat ENUM('사용가능', '사용중', '수리중') NOT NULL DEFAULT '사용가능' COMMENT '현재 상태',
    
    UNIQUE KEY uk_seat_room_num (seat_room, seat_num)
) COMMENT '열람실 좌석 정보';

-- 5.2 좌석 이용 로그
CREATE TABLE seat_reservations (
    res_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '좌석예약 ID',
    seat_id INT NOT NULL COMMENT '좌석 ID (FK)',
    usr_id INT NOT NULL COMMENT '사용자 ID (FK)',
    res_start DATETIME NOT NULL COMMENT '입실 시간',
    res_end DATETIME DEFAULT NULL COMMENT '퇴실 시간',
    res_stat ENUM('이용중', '반납완료', '강제퇴실') NOT NULL DEFAULT '이용중' COMMENT '이용 상태',

    CONSTRAINT fk_res_seats FOREIGN KEY (seat_id)
        REFERENCES seats (seat_id) ON DELETE CASCADE,
    CONSTRAINT fk_res_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE
) COMMENT '좌석 이용 및 예약 이력';


-- 5.3 출입 로그
CREATE TABLE entry_logs (
    log_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '로그 ID',
    usr_id INT NOT NULL COMMENT '사용자 ID',
    log_type ENUM('입실', '퇴실') NOT NULL COMMENT '유형',
    log_time DATETIME NOT NULL COMMENT '시간',
    
    INDEX idx_log_time (log_time),
    CONSTRAINT fk_entry_logs_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE
) COMMENT '도서관 출입 기록';


-- -----------------------------------------------------
-- 6. 커뮤니티 및 활동
-- -----------------------------------------------------

-- 6.1 공지사항
CREATE TABLE notices (
    ntc_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '공지 ID',
    lib_id VARCHAR(30) NOT NULL COMMENT '작성자(사서) ID',
    ntc_title VARCHAR(100) NOT NULL COMMENT '제목',
    ntc_content TEXT COMMENT '내용',
    ntc_file VARCHAR(255) COMMENT '첨부파일',
    ntc_important BOOLEAN NOT NULL DEFAULT FALSE COMMENT '필독 여부',
    ntc_date DATETIME NOT NULL COMMENT '작성일',
    ntc_views INT DEFAULT 0 COMMENT '조회수',
    
    INDEX idx_ntc_date (ntc_date),
    INDEX idx_ntc_important (ntc_important),
    CONSTRAINT fk_notices_librarians FOREIGN KEY (lib_id)
        REFERENCES librarians (lib_id) ON DELETE RESTRICT
) COMMENT '도서관 공지사항';

-- 6.2 도서 리뷰
CREATE TABLE book_reviews (
    rev_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '리뷰 ID',
    bk_id VARCHAR(50) NOT NULL COMMENT '도서 ID',
    usr_id INT NOT NULL COMMENT '작성자 ID',
    rev_title VARCHAR(100) COMMENT '제목',
    rev_rate TINYINT NOT NULL COMMENT '평점',
    rev_content TEXT COMMENT '내용',
    rev_date DATETIME NOT NULL COMMENT '작성일',
    
    UNIQUE KEY uk_review_user_book (usr_id, bk_id),
    CONSTRAINT fk_book_reviews_books FOREIGN KEY (bk_id)
        REFERENCES books (bk_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_reviews_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE
) COMMENT '도서 리뷰 및 평점';

-- 6.3 봉사활동
CREATE TABLE volunteer_activities (
    vol_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '활동 ID',
    usr_id INT NOT NULL COMMENT '신청자 ID',
    vol_date DATE NOT NULL COMMENT '활동 날짜',
    vol_start TIME COMMENT '시작 시간',
    vol_end TIME COMMENT '종료 시간',
    vol_desc VARCHAR(200) COMMENT '활동 내용',
    -- [팀원 피드백 반영] 처리 비고 추가
    vol_note VARCHAR(200) COMMENT '관리자 처리/반려 사유',
    vol_stat ENUM('대기', '승인', '반려', '완료') NOT NULL DEFAULT '대기' COMMENT '상태',
    INDEX idx_vol_stat (vol_stat),
    CONSTRAINT fk_volunteer_activities_users FOREIGN KEY (usr_id)
        REFERENCES users (usr_id) ON DELETE CASCADE
) COMMENT '봉사활동 신청 및 내역';


-- -----------------------------------------------------
-- 7. 통계 및 로그
-- -----------------------------------------------------

-- 7.1 월간 도서 대출 통계
CREATE TABLE monthly_book_stats (
    stat_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '통계 ID',
    stat_year INT NOT NULL COMMENT '연도',
    stat_month INT NOT NULL COMMENT '월',
    bk_id VARCHAR(50) NOT NULL COMMENT '도서 ID',
    loan_cnt INT DEFAULT 0 COMMENT '대출 횟수',
    
    UNIQUE KEY uk_monthly_stats (stat_year, stat_month, bk_id),
    CONSTRAINT fk_monthly_book_stats_books FOREIGN KEY (bk_id)
        REFERENCES books (bk_id) ON DELETE CASCADE
) COMMENT '월별 인기도서 분석 통계';

-- 7.2 AI 스마트 분석 로그
CREATE TABLE ai_analysis_log (
    log_id      BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT '로그 고유 ID',
    lib_id      VARCHAR(30) NOT NULL COMMENT '질문한 사서 ID (FK)',
    quest_text  TEXT NOT NULL COMMENT '사용자 자연어 질문',
    gen_sql     TEXT COMMENT 'AI가 생성한 SQL 쿼리',
    chart_type  VARCHAR(20) COMMENT '시각화 타입',
    error_msg   TEXT COMMENT '에러 메시지',
    exec_time   INT COMMENT '소요 시간',
    cre_at      DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '기록 일시',

    INDEX idx_ai_log_lib (lib_id),
    INDEX idx_ai_log_cre (cre_at),
    CONSTRAINT fk_ai_log_librarians FOREIGN KEY (lib_id)
        REFERENCES librarians (lib_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT 'AI 챗봇 통계 분석 질의 로그';

