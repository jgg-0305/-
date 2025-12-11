-- =========================================================
-- [DCL] 사용자 계정 생성 및 권한 부여
-- 작성일: 2025-12-10
-- 대상: Admin(최고관리자), Staff(사서), Student(학생)
-- =========================================================

-- 1. 계정 생성 (비밀번호는 예시로 '1234' 설정, 실무에선 변경 필수)
-- ---------------------------------------------------------
CREATE USER IF NOT EXISTS 'lib_admin'@'%' IDENTIFIED BY '1234';   -- 시스템 관리자
CREATE USER IF NOT EXISTS 'lib_staff'@'%' IDENTIFIED BY '1234';   -- 사서 (일반/부장 통합)
CREATE USER IF NOT EXISTS 'lib_student'@'%' IDENTIFIED BY '1234'; -- 학생 (웹 서비스용)


-- 2. [Admin] 시스템 최고 관리자
-- : 모든 테이블에 대한 모든 권한 (DDL, DML, DCL 포함)
-- ---------------------------------------------------------
GRANT ALL PRIVILEGES ON library_system.* TO 'lib_admin'@'%' WITH GRANT OPTION;


-- 3. [Librarian] 사서 (일반 직원 & 부장 통합)
-- : 운영에 필요한 조회, 추가, 수정, 삭제 가능 (테이블 날리기 등 위험 권한 제외)
-- ---------------------------------------------------------
-- (1) 기본 CRUD 권한 부여 (모든 테이블)
GRANT SELECT, INSERT, UPDATE, DELETE ON library_system.* TO 'lib_staff'@'%';

-- (2) 위험한 권한 회수 (혹시 모를 사고 방지)
-- 사서가 DROP(테이블 삭제), ALTER(구조 변경) 등을 할 필요는 없음
-- MySQL은 DENY 구문이 없으므로, 위에서 GRANT를 구체적으로 주는 것으로 갈음함.
-- 즉, EXECUTE, CREATE ROUTINE 등의 권한은 주지 않음.


-- 4. [Student] 학생 (일반 사용자)
-- : 조회는 자유롭지만, 수정/삭제는 본인의 신청 내역 등 극히 일부만 가능
-- ---------------------------------------------------------

-- (1) [조회] 기본 정보 테이블 (책, 공지사항, 위치 등은 보기만 가능)
GRANT SELECT ON library_system.books TO 'lib_student'@'%';
GRANT SELECT ON library_system.book_copies TO 'lib_student'@'%';
GRANT SELECT ON library_system.genres TO 'lib_student'@'%';
GRANT SELECT ON library_system.locations TO 'lib_student'@'%';
GRANT SELECT ON library_system.notices TO 'lib_student'@'%';
GRANT SELECT ON library_system.book_reviews TO 'lib_student'@'%';
GRANT SELECT ON library_system.monthly_book_stats TO 'lib_student'@'%'; -- 인기도서 보기용

-- (2) [조회] 내 정보 확인용 (로그인, 내 대출 확인)
GRANT SELECT ON library_system.users TO 'lib_student'@'%';
GRANT SELECT ON library_system.loans TO 'lib_student'@'%';
GRANT SELECT ON library_system.reservations TO 'lib_student'@'%';
GRANT SELECT ON library_system.requests TO 'lib_student'@'%';
GRANT SELECT ON library_system.inter_library_loans TO 'lib_student'@'%';
GRANT SELECT ON library_system.penalties TO 'lib_student'@'%';
GRANT SELECT ON library_system.entry_logs TO 'lib_student'@'%'; -- 본인 기록 조회용

-- (3) [쓰기/수정] 학생이 직접 '신청'하거나 '작성'하는 테이블
-- 희망도서 신청
GRANT INSERT, UPDATE, DELETE ON library_system.requests TO 'lib_student'@'%';

-- 상호대차 신청
GRANT INSERT, UPDATE ON library_system.inter_library_loans TO 'lib_student'@'%';

-- 도서 예약 (취소 포함)
GRANT INSERT, UPDATE ON library_system.reservations TO 'lib_student'@'%';

-- 리뷰 작성
GRANT INSERT, UPDATE, DELETE ON library_system.book_reviews TO 'lib_student'@'%';

-- 좌석 예약 (입실/퇴실 트랜잭션용)
GRANT SELECT, UPDATE ON library_system.seats TO 'lib_student'@'%';
GRANT INSERT, UPDATE ON library_system.seat_reservations TO 'lib_student'@'%';

-- (4) [보안] 접근 금지 테이블 (권한 안 줌)
-- librarians (사서 목록), ai_analysis_log (내부 로그) 등은 학생이 볼 필요 없음


-- 5. 권한 적용 (새로고침)
-- ---------------------------------------------------------
FLUSH PRIVILEGES;