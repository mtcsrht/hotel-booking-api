COMMENT ON TABLE users IS 'Refresh / verification / password-reset tokens and per-IP rate limits live in Redis with TTL';

COMMENT ON COLUMN users.email IS 'Login name, store lower-cased. Unique among non-deleted users; a deleted user''s email can register again';

COMMENT ON COLUMN users.password_hash IS 'BCrypt/Argon2 hash, never plain text';

COMMENT ON COLUMN users.email_verified_at IS 'NULL = not verified yet';

COMMENT ON COLUMN users.failed_login_attempts IS 'Reset to 0 on successful login';

COMMENT ON COLUMN users.locked_until IS 'Set after e.g. 5 failed attempts; NULL or past = not locked';

COMMENT ON COLUMN users.deleted_at IS 'Soft delete: NULL = live row';

COMMENT ON TABLE login_logs IS 'Personal data (IP) under GDPR: delete rows older than e.g. 90 days with a scheduled job';

COMMENT ON COLUMN login_logs.id IS 'High-volume append-only log: bigint is cheaper than uuid';

COMMENT ON COLUMN login_logs.user_id IS 'NULL when the email does not exist';

COMMENT ON COLUMN login_logs.country_code IS 'From GeoIP lookup on ip_address';

COMMENT ON TABLE hotels IS 'Searchable only when status = PUBLISHED AND is_active AND deleted_at IS NULL';

COMMENT ON COLUMN hotels.rejection_reason IS 'Filled when status = REJECTED or SUSPENDED';

COMMENT ON COLUMN hotels.approved_by IS 'ADMIN who published it';

COMMENT ON COLUMN hotels.star_rating IS '1-5, nullable for unrated properties';

COMMENT ON COLUMN hotels.country_code IS 'ISO 3166-1 alpha-2, e.g. HU';

COMMENT ON COLUMN hotels.timezone IS 'IANA zone, e.g. Europe/Budapest. All local times/deadlines are computed in it';

COMMENT ON COLUMN hotels.currency IS 'ISO 4217. Single currency for all prices of this hotel';

COMMENT ON COLUMN hotels.check_in_from IS 'Hotel local time';

COMMENT ON COLUMN hotels.check_out_until IS 'Hotel local time';

COMMENT ON COLUMN hotels.free_cancellation_hours IS 'Free cancel until N hours before check-in';

COMMENT ON COLUMN hotels.late_cancellation_fee_percent IS '0-100, charged when cancelling after the free window';

COMMENT ON COLUMN hotels.tourist_tax_per_adult_per_night IS 'Local tourist tax, children usually exempt';

COMMENT ON COLUMN hotels.is_active IS 'Temporarily unbookable even if PUBLISHED';

COMMENT ON COLUMN hotels.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN hotels.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN hotels.deleted_at IS 'Soft delete: NULL = live row';

COMMENT ON TABLE hotel_staff IS 'Which HOTEL_MANAGER user can manage which hotel. Checked in @PreAuthorize';

COMMENT ON COLUMN hotel_staff.deleted_at IS 'Soft delete: NULL = still works there';

COMMENT ON COLUMN hotel_images.object_key IS 'Key in MinIO/S3 bucket, not a full URL';

COMMENT ON COLUMN amenities.code IS 'WIFI, POOL, PARKING, AIR_CONDITIONING...';

COMMENT ON COLUMN amenities.icon IS 'Icon name for a future frontend';

COMMENT ON COLUMN rooms.room_number IS 'Unique within a hotel among non-deleted rooms';

COMMENT ON COLUMN rooms.base_price_per_night IS 'In hotels.currency. Fallback when no room_rates row exists';

COMMENT ON COLUMN rooms.is_active IS 'Out of service indefinitely. Date ranges -> room_blocks';

COMMENT ON COLUMN rooms.version IS 'JPA @Version for admin edits. Booking uses PESSIMISTIC_WRITE on this row';

COMMENT ON COLUMN rooms.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN rooms.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN rooms.deleted_at IS 'Soft delete: NULL = live row';

COMMENT ON TABLE room_blocks IS 'Creating a block must also lock the room row and reject if it overlaps an active booking';

COMMENT ON COLUMN room_blocks.end_date IS 'Exclusive, same convention as check_out_date. CHECK (end_date > start_date)';

COMMENT ON COLUMN room_blocks.reason IS 'Renovation, maintenance, owner use...';

COMMENT ON COLUMN room_blocks.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN room_blocks.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN room_blocks.deleted_at IS 'Soft delete = block lifted';

COMMENT ON COLUMN room_images.object_key IS 'Key in MinIO/S3 bucket';

COMMENT ON TABLE room_rates IS 'Seasonal / weekend pricing per room type. Total = sum of nights, falling back to rooms.base_price_per_night';

COMMENT ON COLUMN room_rates.stay_date IS 'One row per night';

COMMENT ON COLUMN room_rates.price_per_night IS 'In hotels.currency';

COMMENT ON COLUMN room_rates.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN room_rates.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON TABLE services IS 'Global catalog. No price here - each hotel sets its own in hotel_services';

COMMENT ON COLUMN services.code IS 'BREAKFAST, HALF_BOARD, FULL_BOARD, ALL_INCLUSIVE...';

COMMENT ON COLUMN services.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN services.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN services.deleted_at IS 'Soft delete: NULL = live row';

COMMENT ON COLUMN hotel_services.price_per_person_per_night IS 'In hotels.currency';

COMMENT ON COLUMN hotel_services.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN hotel_services.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN hotel_services.deleted_at IS 'Soft delete: NULL = live row';

COMMENT ON TABLE promo_codes IS 'Per-user usage = COUNT(bookings WHERE user_id AND promo_code_id AND status NOT IN (CANCELLED, EXPIRED))';

COMMENT ON COLUMN promo_codes.code IS 'Store upper-cased, e.g. SUMMER26';

COMMENT ON COLUMN promo_codes.hotel_id IS 'NULL = valid on every hotel (platform promo, ADMIN only)';

COMMENT ON COLUMN promo_codes.discount_value IS 'Percent (0-100) or fixed amount';

COMMENT ON COLUMN promo_codes.max_discount_amount IS 'Cap for PERCENT codes';

COMMENT ON COLUMN promo_codes.max_uses IS 'NULL = unlimited';

COMMENT ON COLUMN promo_codes.used_count IS 'Incremented under PESSIMISTIC_WRITE lock on this row';

COMMENT ON COLUMN promo_codes.created_by IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN promo_codes.updated_by IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN promo_codes.deleted_at IS 'Soft delete: NULL = live row';

COMMENT ON TABLE bookings IS 'Never deleted, only CANCELLED/EXPIRED (audit/financial history)';

COMMENT ON COLUMN bookings.reference IS 'Human-friendly code, e.g. BK7F3K9Q';

COMMENT ON COLUMN bookings.user_id IS 'Account that booked and pays';

COMMENT ON COLUMN bookings.hotel_service_id IS 'NULL = room only';

COMMENT ON COLUMN bookings.guest_first_name IS 'Who actually stays; defaults to the user';

COMMENT ON COLUMN bookings.check_out_date IS 'CHECK (check_out_date > check_in_date)';

COMMENT ON COLUMN bookings.expires_at IS 'Only for PENDING: hold ends here';

COMMENT ON COLUMN bookings.room_price_total IS 'Snapshot at booking time';

COMMENT ON COLUMN bookings.service_price_total IS 'Snapshot';

COMMENT ON COLUMN bookings.discount_total IS 'From promo code';

COMMENT ON COLUMN bookings.tax_total IS 'Tourist tax: adults x nights x hotel rate';

COMMENT ON COLUMN bookings.total_price IS 'room + service - discount + tax';

COMMENT ON COLUMN bookings.currency IS 'Snapshot of hotels.currency';

COMMENT ON COLUMN bookings.free_cancellation_until IS 'Computed in hotel timezone, stored as UTC instant';

COMMENT ON COLUMN bookings.late_cancellation_fee_percent IS 'Snapshot of hotel policy';

COMMENT ON COLUMN bookings.version IS 'JPA @Version: confirm vs cancel race';

COMMENT ON CONSTRAINT bookings_no_overlap ON bookings IS 'Backstop against double booking; check_out_date is exclusive, so same-day turnover is allowed. A PENDING hold blocks its dates even past expires_at, so mark overlapping stale holds EXPIRED in the same transaction before inserting';

COMMENT ON COLUMN booking_status_history.from_status IS 'NULL for the initial PENDING';

COMMENT ON COLUMN booking_status_history.changed_by IS 'NULL = system (expiry job, payment webhook)';

COMMENT ON COLUMN payments.amount IS 'Always positive, type says direction';

COMMENT ON COLUMN payments.provider IS 'MOCK, STRIPE...';

COMMENT ON COLUMN payments.provider_reference IS 'ID from the provider, set after the call';

COMMENT ON COLUMN payments.idempotency_key IS 'Prevents double charge on retries';

COMMENT ON COLUMN payments.refunded_payment_id IS 'For REFUND rows: which CHARGE it refunds';

COMMENT ON TABLE reviews IS 'Average rating + count cached in Redis per hotel, evicted on new review';

COMMENT ON COLUMN reviews.booking_id IS 'One review per stay, only if booking is COMPLETED';

COMMENT ON COLUMN reviews.hotel_id IS 'Denormalized from booking for fast per-hotel queries';

COMMENT ON COLUMN reviews.rating IS 'CHECK 1-10, like Booking.com';

COMMENT ON COLUMN reviews.hotel_response IS 'Reply from hotel staff';

COMMENT ON COLUMN reviews.deleted_at IS 'Soft delete, e.g. moderation';

COMMENT ON TABLE emails IS 'Transactional outbox: inserted in the same DB transaction as the booking, sent by a @Scheduled worker';

COMMENT ON COLUMN emails.user_id IS 'NULL for non-user recipients';

COMMENT ON COLUMN emails.booking_id IS 'Context, e.g. confirmation or reminder';

COMMENT ON COLUMN emails.template IS 'BOOKING_CONFIRMED, CHECK_IN_REMINDER, VERIFY_EMAIL, HOTEL_APPROVED...';

COMMENT ON COLUMN emails.payload IS 'Template variables; rendered at send time';

COMMENT ON COLUMN emails.scheduled_at IS 'now() = ASAP, future = scheduled';

COMMENT ON COLUMN emails.dedup_key IS 'e.g. CHECK_IN_REMINDER:<booking_id>, prevents duplicates';
