-- Checks the constraints in ddl/ fire. Changes nothing: everything rolls back.
-- docker compose exec -T postgres psql -U hotel_booking -d hotel_booking -v ON_ERROR_STOP=1 < constraints_test.sql
BEGIN;

CREATE FUNCTION pg_temp.rejects(stmt text, expected text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE actual text;
BEGIN
  EXECUTE stmt;
  RAISE EXCEPTION 'NOT REJECTED (expected %): %', expected, stmt;
EXCEPTION WHEN check_violation OR unique_violation OR exclusion_violation THEN
  GET STACKED DIAGNOSTICS actual = CONSTRAINT_NAME;
  IF actual <> expected THEN
    RAISE EXCEPTION 'Rejected by % instead of %: %', actual, expected, stmt;
  END IF;
END $$;

CREATE FUNCTION pg_temp.book(ref text, room uuid, check_in date, check_out date) RETURNS void LANGUAGE sql AS $$
  INSERT INTO bookings (reference, user_id, room_id, guest_first_name, guest_last_name, check_in_date, check_out_date,
                        room_price_total, total_price, currency, free_cancellation_until, late_cancellation_fee_percent)
  VALUES (ref, '00000000-0000-7000-8000-000000000001', room, 'A', 'B', check_in, check_out, 200, 200, 'EUR', now(), 100);
$$;

INSERT INTO users (id, email, password_hash, first_name, last_name)
VALUES ('00000000-0000-7000-8000-000000000001', 'a@example.com', 'x', 'A', 'B');
INSERT INTO hotels (id, name, address_line, city, country_code, timezone)
VALUES ('00000000-0000-7000-8000-000000000002', 'H', 'Street 1', 'Budapest', 'HU', 'Europe/Budapest');
INSERT INTO rooms (id, hotel_id, room_number, type, max_occupancy, base_price_per_night)
VALUES ('00000000-0000-7000-8000-000000000003', '00000000-0000-7000-8000-000000000002', '101', 'DOUBLE', 2, 100),
       ('00000000-0000-7000-8000-000000000007', '00000000-0000-7000-8000-000000000002', '102', 'DOUBLE', 2, 100);
INSERT INTO services (id, code, name) VALUES ('00000000-0000-7000-8000-000000000004', 'BREAKFAST', 'Breakfast');
INSERT INTO hotel_services (hotel_id, service_id, price_per_person_per_night)
VALUES ('00000000-0000-7000-8000-000000000002', '00000000-0000-7000-8000-000000000004', 10);
INSERT INTO hotel_staff (user_id, hotel_id)
VALUES ('00000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000002');
INSERT INTO bookings (id, reference, user_id, room_id, guest_first_name, guest_last_name, check_in_date, check_out_date,
                      room_price_total, total_price, currency, free_cancellation_until, late_cancellation_fee_percent)
VALUES ('00000000-0000-7000-8000-000000000005', 'BK000001', '00000000-0000-7000-8000-000000000001',
        '00000000-0000-7000-8000-000000000003', 'A', 'B', '2027-01-01', '2027-01-03', 200, 200, 'EUR', now(), 100);
INSERT INTO payments (id, booking_id, amount, currency, provider, idempotency_key)
VALUES ('00000000-0000-7000-8000-000000000006', '00000000-0000-7000-8000-000000000005', 200, 'EUR', 'MOCK', 'charge-1');

-- Ids default to UUIDv7.
DO $$ BEGIN
  ASSERT (SELECT bool_and(uuid_extract_version(id) = 7) FROM hotel_services);
END $$;

-- CHECK constraints.
SELECT pg_temp.rejects($s$UPDATE users SET email = 'A@example.com'$s$, 'users_email_lowercase');
SELECT pg_temp.rejects($s$UPDATE hotels SET star_rating = 6$s$, 'hotels_star_rating_range');
SELECT pg_temp.rejects($s$UPDATE hotels SET late_cancellation_fee_percent = 101$s$, 'hotels_late_fee_range');
SELECT pg_temp.rejects($s$INSERT INTO room_blocks (room_id, start_date, end_date)
  VALUES ('00000000-0000-7000-8000-000000000003', '2027-01-02', '2027-01-02')$s$, 'room_blocks_date_order');
SELECT pg_temp.rejects($s$INSERT INTO promo_codes (code, discount_type, discount_value, valid_from, valid_until)
  VALUES ('summer', 'FIXED_AMOUNT', 5, now(), now())$s$, 'promo_codes_code_uppercase');
SELECT pg_temp.rejects($s$INSERT INTO promo_codes (code, discount_type, discount_value, valid_from, valid_until)
  VALUES ('SUMMER', 'PERCENT', 101, now(), now())$s$, 'promo_codes_percent_range');
INSERT INTO promo_codes (code, discount_type, discount_value, valid_from, valid_until)
  VALUES ('FIXED150', 'FIXED_AMOUNT', 150, now(), now());  -- above 100 is fine when not a percent
SELECT pg_temp.rejects($s$UPDATE bookings SET check_out_date = check_in_date$s$, 'bookings_date_order');
SELECT pg_temp.rejects($s$UPDATE bookings SET check_out_date = check_in_date - 1$s$, 'bookings_date_order');
SELECT pg_temp.rejects($s$UPDATE bookings SET late_cancellation_fee_percent = -1$s$, 'bookings_late_fee_range');
SELECT pg_temp.rejects($s$UPDATE bookings SET total_price = 199.99$s$, 'bookings_total_price');
SELECT pg_temp.rejects($s$UPDATE payments SET amount = 0$s$, 'payments_amount_positive');
SELECT pg_temp.rejects($s$UPDATE payments SET type = 'REFUND'$s$, 'payments_refund_link');
SELECT pg_temp.rejects($s$UPDATE payments SET refunded_payment_id = id$s$, 'payments_refund_link');
SELECT pg_temp.rejects($s$INSERT INTO reviews (booking_id, user_id, hotel_id, rating)
  VALUES ('00000000-0000-7000-8000-000000000005', '00000000-0000-7000-8000-000000000001',
          '00000000-0000-7000-8000-000000000002', 11)$s$, 'reviews_rating_range');

-- Double booking. Fixture BK000001: room 101, 2027-01-01 to 2027-01-03, PENDING.
SELECT pg_temp.rejects($s$SELECT pg_temp.book('BK2', '00000000-0000-7000-8000-000000000003', '2027-01-02', '2027-01-04')$s$, 'bookings_no_overlap');
UPDATE bookings SET status = 'CONFIRMED' WHERE reference = 'BK000001';
SELECT pg_temp.rejects($s$SELECT pg_temp.book('BK2', '00000000-0000-7000-8000-000000000003', '2027-01-01', '2027-01-03')$s$, 'bookings_no_overlap');
-- Same-day turnover on either side, and the same dates in another room, are allowed.
SELECT pg_temp.book('BK3', '00000000-0000-7000-8000-000000000003', '2027-01-03', '2027-01-05');
SELECT pg_temp.book('BK4', '00000000-0000-7000-8000-000000000003', '2026-12-30', '2027-01-01');
SELECT pg_temp.book('BK5', '00000000-0000-7000-8000-000000000007', '2027-01-01', '2027-01-03');
-- Moving an existing booking onto taken dates is rejected.
SELECT pg_temp.rejects($s$UPDATE bookings SET check_in_date = '2027-01-02' WHERE reference = 'BK3'$s$, 'bookings_no_overlap');
-- An expired hold frees its dates, and cannot be revived once they are taken.
UPDATE bookings SET status = 'EXPIRED' WHERE reference = 'BK000001';
SELECT pg_temp.book('BK6', '00000000-0000-7000-8000-000000000003', '2027-01-01', '2027-01-03');
SELECT pg_temp.rejects($s$UPDATE bookings SET status = 'PENDING' WHERE reference = 'BK000001'$s$, 'bookings_no_overlap');

-- Live duplicates are rejected.
SELECT pg_temp.rejects($s$INSERT INTO users (email, password_hash, first_name, last_name)
  VALUES ('a@example.com', 'x', 'A', 'B')$s$, 'users_email_idx');
SELECT pg_temp.rejects($s$INSERT INTO rooms (hotel_id, room_number, type, max_occupancy, base_price_per_night)
  VALUES ('00000000-0000-7000-8000-000000000002', '101', 'SINGLE', 1, 50)$s$, 'rooms_hotel_id_room_number_idx');
SELECT pg_temp.rejects($s$INSERT INTO hotel_staff (user_id, hotel_id)
  VALUES ('00000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000002')$s$, 'hotel_staff_user_id_hotel_id_idx');
SELECT pg_temp.rejects($s$INSERT INTO hotel_services (hotel_id, service_id, price_per_person_per_night)
  VALUES ('00000000-0000-7000-8000-000000000002', '00000000-0000-7000-8000-000000000004', 12)$s$, 'hotel_services_hotel_id_service_id_idx');

-- Re-creating after a soft delete is allowed.
UPDATE rooms SET deleted_at = now();
UPDATE hotel_staff SET deleted_at = now();
UPDATE hotel_services SET deleted_at = now();
UPDATE users SET deleted_at = now();
INSERT INTO users (email, password_hash, first_name, last_name) VALUES ('a@example.com', 'x', 'A', 'B');
INSERT INTO rooms (hotel_id, room_number, type, max_occupancy, base_price_per_night)
VALUES ('00000000-0000-7000-8000-000000000002', '101', 'SINGLE', 1, 50);
INSERT INTO hotel_staff (user_id, hotel_id)
VALUES ('00000000-0000-7000-8000-000000000001', '00000000-0000-7000-8000-000000000002');
INSERT INTO hotel_services (hotel_id, service_id, price_per_person_per_night)
VALUES ('00000000-0000-7000-8000-000000000002', '00000000-0000-7000-8000-000000000004', 12);

\echo 'constraints_test: all passed'
ROLLBACK;
