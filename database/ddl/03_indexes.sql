CREATE UNIQUE INDEX ON users (email) WHERE deleted_at IS NULL;

CREATE INDEX ON login_logs (user_id, created_at);

CREATE INDEX ON login_logs (ip_address, created_at);

CREATE INDEX ON hotels (country_code, city);

CREATE INDEX ON hotels (status);

CREATE INDEX ON hotels (deleted_at);

CREATE UNIQUE INDEX ON hotel_staff (user_id, hotel_id) WHERE deleted_at IS NULL;

CREATE INDEX ON hotel_staff (hotel_id);

CREATE INDEX ON hotel_images (hotel_id, sort_order);

CREATE INDEX ON hotel_amenities (amenity_id);

CREATE UNIQUE INDEX ON rooms (hotel_id, room_number) WHERE deleted_at IS NULL;

CREATE INDEX ON rooms (hotel_id, type);

CREATE INDEX ON room_blocks (room_id, start_date, end_date);

CREATE INDEX ON room_images (room_id, sort_order);

CREATE UNIQUE INDEX ON room_rates (hotel_id, room_type, stay_date);

CREATE UNIQUE INDEX ON hotel_services (hotel_id, service_id) WHERE deleted_at IS NULL;

CREATE INDEX ON bookings (room_id, check_in_date, check_out_date);

CREATE INDEX ON bookings (status, expires_at);

CREATE INDEX ON bookings (user_id);

CREATE INDEX ON bookings (promo_code_id);

CREATE INDEX ON booking_status_history (booking_id, created_at);

CREATE INDEX ON payments (booking_id);

CREATE INDEX ON reviews (hotel_id, created_at);

CREATE INDEX ON emails (status, scheduled_at);

CREATE INDEX ON emails (booking_id);
