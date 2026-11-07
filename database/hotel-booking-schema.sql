CREATE TYPE "room_type" AS ENUM (
  'SINGLE',
  'DOUBLE',
  'TWIN',
  'SUITE',
  'FAMILY'
);

CREATE TYPE "user_role" AS ENUM (
  'GUEST',
  'HOTEL_MANAGER',
  'ADMIN'
);

CREATE TYPE "staff_role" AS ENUM (
  'OWNER',
  'MANAGER',
  'RECEPTIONIST'
);

CREATE TYPE "hotel_status" AS ENUM (
  'DRAFT',
  'PENDING_APPROVAL',
  'PUBLISHED',
  'REJECTED',
  'SUSPENDED'
);

CREATE TYPE "booking_status" AS ENUM (
  'PENDING',
  'CONFIRMED',
  'CANCELLED',
  'EXPIRED',
  'COMPLETED',
  'NO_SHOW'
);

CREATE TYPE "payment_type" AS ENUM (
  'CHARGE',
  'REFUND'
);

CREATE TYPE "payment_status" AS ENUM (
  'INITIATED',
  'SUCCEEDED',
  'FAILED'
);

CREATE TYPE "discount_type" AS ENUM (
  'PERCENT',
  'FIXED_AMOUNT'
);

CREATE TYPE "amenity_scope" AS ENUM (
  'HOTEL',
  'ROOM',
  'BOTH'
);

CREATE TYPE "login_result" AS ENUM (
  'SUCCESS',
  'BAD_CREDENTIALS',
  'UNKNOWN_EMAIL',
  'ACCOUNT_LOCKED',
  'EMAIL_NOT_VERIFIED'
);

CREATE TYPE "email_status" AS ENUM (
  'PENDING',
  'SENDING',
  'SENT',
  'FAILED',
  'CANCELLED'
);

CREATE TABLE "users" (
  "id" uuid PRIMARY KEY NOT NULL,
  "email" varchar(255) UNIQUE NOT NULL,
  "password_hash" varchar(255) NOT NULL,
  "first_name" varchar(100) NOT NULL,
  "last_name" varchar(100) NOT NULL,
  "phone" varchar(30),
  "role" user_role NOT NULL DEFAULT 'GUEST',
  "email_verified_at" timestamptz,
  "failed_login_attempts" smallint NOT NULL DEFAULT 0,
  "locked_until" timestamptz,
  "last_login_at" timestamptz,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "login_logs" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "user_id" uuid,
  "email_attempted" varchar(255) NOT NULL,
  "result" login_result NOT NULL,
  "ip_address" inet NOT NULL,
  "user_agent" varchar(512),
  "country_code" char(2),
  "city" varchar(100),
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "favorites" (
  "user_id" uuid NOT NULL,
  "hotel_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  PRIMARY KEY ("user_id", "hotel_id")
);

CREATE TABLE "hotels" (
  "id" uuid PRIMARY KEY NOT NULL,
  "name" varchar(150) NOT NULL,
  "description" text,
  "status" hotel_status NOT NULL DEFAULT 'DRAFT',
  "rejection_reason" varchar(500),
  "approved_by" uuid,
  "approved_at" timestamptz,
  "star_rating" smallint,
  "address_line" varchar(255) NOT NULL,
  "city" varchar(100) NOT NULL,
  "country_code" char(2) NOT NULL,
  "postal_code" varchar(20),
  "latitude" decimal(9,6),
  "longitude" decimal(9,6),
  "timezone" varchar(50) NOT NULL,
  "currency" char(3) NOT NULL DEFAULT 'EUR',
  "check_in_from" time NOT NULL DEFAULT '14:00',
  "check_out_until" time NOT NULL DEFAULT '11:00',
  "free_cancellation_hours" smallint NOT NULL DEFAULT 48,
  "late_cancellation_fee_percent" smallint NOT NULL DEFAULT 100,
  "tourist_tax_per_adult_per_night" decimal(10,2) NOT NULL DEFAULT 0,
  "contact_email" varchar(255),
  "contact_phone" varchar(30),
  "is_active" boolean NOT NULL DEFAULT true,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "hotel_staff" (
  "id" uuid PRIMARY KEY NOT NULL,
  "user_id" uuid NOT NULL,
  "hotel_id" uuid NOT NULL,
  "staff_role" staff_role NOT NULL DEFAULT 'MANAGER',
  "created_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "hotel_images" (
  "id" uuid PRIMARY KEY NOT NULL,
  "hotel_id" uuid NOT NULL,
  "object_key" varchar(500) NOT NULL,
  "alt_text" varchar(255),
  "sort_order" smallint NOT NULL DEFAULT 0,
  "is_cover" boolean NOT NULL DEFAULT false,
  "created_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "amenities" (
  "id" uuid PRIMARY KEY NOT NULL,
  "code" varchar(40) UNIQUE NOT NULL,
  "name" varchar(100) NOT NULL,
  "scope" amenity_scope NOT NULL,
  "icon" varchar(50)
);

CREATE TABLE "hotel_amenities" (
  "hotel_id" uuid NOT NULL,
  "amenity_id" uuid NOT NULL,
  PRIMARY KEY ("hotel_id", "amenity_id")
);

CREATE TABLE "rooms" (
  "id" uuid PRIMARY KEY NOT NULL,
  "hotel_id" uuid NOT NULL,
  "room_number" varchar(10) NOT NULL,
  "type" room_type NOT NULL,
  "floor" smallint,
  "max_occupancy" smallint NOT NULL,
  "bed_count" smallint NOT NULL DEFAULT 1,
  "size_sqm" decimal(6,2),
  "base_price_per_night" decimal(10,2) NOT NULL,
  "is_active" boolean NOT NULL DEFAULT true,
  "version" integer NOT NULL DEFAULT 0,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "room_blocks" (
  "id" uuid PRIMARY KEY NOT NULL,
  "room_id" uuid NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "reason" varchar(255),
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "room_images" (
  "id" uuid PRIMARY KEY NOT NULL,
  "room_id" uuid NOT NULL,
  "object_key" varchar(500) NOT NULL,
  "alt_text" varchar(255),
  "sort_order" smallint NOT NULL DEFAULT 0,
  "is_cover" boolean NOT NULL DEFAULT false,
  "created_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "room_amenities" (
  "room_id" uuid NOT NULL,
  "amenity_id" uuid NOT NULL,
  PRIMARY KEY ("room_id", "amenity_id")
);

CREATE TABLE "room_rates" (
  "id" uuid PRIMARY KEY NOT NULL,
  "hotel_id" uuid NOT NULL,
  "room_type" room_type NOT NULL,
  "stay_date" date NOT NULL,
  "price_per_night" decimal(10,2) NOT NULL,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "services" (
  "id" uuid PRIMARY KEY NOT NULL,
  "code" varchar(30) UNIQUE NOT NULL,
  "name" varchar(100) NOT NULL,
  "description" text,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "hotel_services" (
  "id" uuid PRIMARY KEY NOT NULL,
  "hotel_id" uuid NOT NULL,
  "service_id" uuid NOT NULL,
  "price_per_person_per_night" decimal(10,2) NOT NULL,
  "is_available" boolean NOT NULL DEFAULT true,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "promo_codes" (
  "id" uuid PRIMARY KEY NOT NULL,
  "code" varchar(30) UNIQUE NOT NULL,
  "hotel_id" uuid,
  "discount_type" discount_type NOT NULL,
  "discount_value" decimal(10,2) NOT NULL,
  "max_discount_amount" decimal(10,2),
  "min_nights" smallint NOT NULL DEFAULT 1,
  "valid_from" timestamptz NOT NULL,
  "valid_until" timestamptz NOT NULL,
  "max_uses" integer,
  "used_count" integer NOT NULL DEFAULT 0,
  "max_uses_per_user" smallint NOT NULL DEFAULT 1,
  "is_active" boolean NOT NULL DEFAULT true,
  "created_by" uuid,
  "updated_by" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "bookings" (
  "id" uuid PRIMARY KEY NOT NULL,
  "reference" varchar(12) UNIQUE NOT NULL,
  "user_id" uuid NOT NULL,
  "room_id" uuid NOT NULL,
  "hotel_service_id" uuid,
  "promo_code_id" uuid,
  "guest_first_name" varchar(100) NOT NULL,
  "guest_last_name" varchar(100) NOT NULL,
  "check_in_date" date NOT NULL,
  "check_out_date" date NOT NULL,
  "adults" smallint NOT NULL DEFAULT 1,
  "children" smallint NOT NULL DEFAULT 0,
  "status" booking_status NOT NULL DEFAULT 'PENDING',
  "expires_at" timestamptz,
  "room_price_total" decimal(10,2) NOT NULL,
  "service_price_total" decimal(10,2) NOT NULL DEFAULT 0,
  "discount_total" decimal(10,2) NOT NULL DEFAULT 0,
  "tax_total" decimal(10,2) NOT NULL DEFAULT 0,
  "total_price" decimal(10,2) NOT NULL,
  "currency" char(3) NOT NULL,
  "free_cancellation_until" timestamptz NOT NULL,
  "late_cancellation_fee_percent" smallint NOT NULL,
  "special_requests" text,
  "confirmed_at" timestamptz,
  "cancelled_at" timestamptz,
  "cancellation_reason" varchar(500),
  "version" integer NOT NULL DEFAULT 0,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "booking_status_history" (
  "id" bigserial PRIMARY KEY NOT NULL,
  "booking_id" uuid NOT NULL,
  "from_status" booking_status,
  "to_status" booking_status NOT NULL,
  "changed_by" uuid,
  "reason" varchar(500),
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "payments" (
  "id" uuid PRIMARY KEY NOT NULL,
  "booking_id" uuid NOT NULL,
  "type" payment_type NOT NULL DEFAULT 'CHARGE',
  "status" payment_status NOT NULL DEFAULT 'INITIATED',
  "amount" decimal(10,2) NOT NULL,
  "currency" char(3) NOT NULL,
  "provider" varchar(30) NOT NULL,
  "provider_reference" varchar(100) UNIQUE,
  "idempotency_key" varchar(64) UNIQUE NOT NULL,
  "failure_reason" varchar(500),
  "refunded_payment_id" uuid,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "reviews" (
  "id" uuid PRIMARY KEY NOT NULL,
  "booking_id" uuid UNIQUE NOT NULL,
  "user_id" uuid NOT NULL,
  "hotel_id" uuid NOT NULL,
  "rating" smallint NOT NULL,
  "title" varchar(150),
  "comment" text,
  "hotel_response" text,
  "responded_by" uuid,
  "responded_at" timestamptz,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now()),
  "deleted_at" timestamptz
);

CREATE TABLE "emails" (
  "id" uuid PRIMARY KEY NOT NULL,
  "user_id" uuid,
  "booking_id" uuid,
  "to_address" varchar(255) NOT NULL,
  "template" varchar(50) NOT NULL,
  "payload" jsonb NOT NULL DEFAULT '{}',
  "status" email_status NOT NULL DEFAULT 'PENDING',
  "scheduled_at" timestamptz NOT NULL DEFAULT (now()),
  "attempts" smallint NOT NULL DEFAULT 0,
  "last_error" text,
  "sent_at" timestamptz,
  "dedup_key" varchar(150) UNIQUE,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "updated_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE INDEX ON "login_logs" ("user_id", "created_at");

CREATE INDEX ON "login_logs" ("ip_address", "created_at");

CREATE INDEX ON "hotels" ("country_code", "city");

CREATE INDEX ON "hotels" ("status");

CREATE INDEX ON "hotels" ("deleted_at");

CREATE UNIQUE INDEX ON "hotel_staff" ("user_id", "hotel_id");

CREATE INDEX ON "hotel_staff" ("hotel_id");

CREATE INDEX ON "hotel_images" ("hotel_id", "sort_order");

CREATE INDEX ON "hotel_amenities" ("amenity_id");

CREATE UNIQUE INDEX ON "rooms" ("hotel_id", "room_number");

CREATE INDEX ON "rooms" ("hotel_id", "type");

CREATE INDEX ON "room_blocks" ("room_id", "start_date", "end_date");

CREATE INDEX ON "room_images" ("room_id", "sort_order");

CREATE UNIQUE INDEX ON "room_rates" ("hotel_id", "room_type", "stay_date");

CREATE UNIQUE INDEX ON "hotel_services" ("hotel_id", "service_id");

CREATE INDEX ON "bookings" ("room_id", "check_in_date", "check_out_date");

CREATE INDEX ON "bookings" ("status", "expires_at");

CREATE INDEX ON "bookings" ("user_id");

CREATE INDEX ON "bookings" ("promo_code_id");

CREATE INDEX ON "booking_status_history" ("booking_id", "created_at");

CREATE INDEX ON "payments" ("booking_id");

CREATE INDEX ON "reviews" ("hotel_id", "created_at");

CREATE INDEX ON "emails" ("status", "scheduled_at");

CREATE INDEX ON "emails" ("booking_id");

COMMENT ON TABLE "users" IS 'Refresh / verification / password-reset tokens and per-IP rate limits live in Redis with TTL';

COMMENT ON COLUMN "users"."email" IS 'Login name, store lower-cased';

COMMENT ON COLUMN "users"."password_hash" IS 'BCrypt/Argon2 hash, never plain text';

COMMENT ON COLUMN "users"."email_verified_at" IS 'NULL = not verified yet';

COMMENT ON COLUMN "users"."failed_login_attempts" IS 'Reset to 0 on successful login';

COMMENT ON COLUMN "users"."locked_until" IS 'Set after e.g. 5 failed attempts; NULL or past = not locked';

COMMENT ON COLUMN "users"."deleted_at" IS 'Soft delete: NULL = live row';

COMMENT ON TABLE "login_logs" IS 'Personal data (IP) under GDPR: delete rows older than e.g. 90 days with a scheduled job';

COMMENT ON COLUMN "login_logs"."id" IS 'High-volume append-only log: bigint is cheaper than uuid';

COMMENT ON COLUMN "login_logs"."user_id" IS 'NULL when the email does not exist';

COMMENT ON COLUMN "login_logs"."country_code" IS 'From GeoIP lookup on ip_address';

COMMENT ON TABLE "hotels" IS 'Searchable only when status = PUBLISHED AND is_active AND deleted_at IS NULL';

COMMENT ON COLUMN "hotels"."rejection_reason" IS 'Filled when status = REJECTED or SUSPENDED';

COMMENT ON COLUMN "hotels"."approved_by" IS 'ADMIN who published it';

COMMENT ON COLUMN "hotels"."star_rating" IS '1-5, nullable for unrated properties';

COMMENT ON COLUMN "hotels"."country_code" IS 'ISO 3166-1 alpha-2, e.g. HU';

COMMENT ON COLUMN "hotels"."timezone" IS 'IANA zone, e.g. Europe/Budapest. All local times/deadlines are computed in it';

COMMENT ON COLUMN "hotels"."currency" IS 'ISO 4217. Single currency for all prices of this hotel';

COMMENT ON COLUMN "hotels"."check_in_from" IS 'Hotel local time';

COMMENT ON COLUMN "hotels"."check_out_until" IS 'Hotel local time';

COMMENT ON COLUMN "hotels"."free_cancellation_hours" IS 'Free cancel until N hours before check-in';

COMMENT ON COLUMN "hotels"."late_cancellation_fee_percent" IS '0-100, charged when cancelling after the free window';

COMMENT ON COLUMN "hotels"."tourist_tax_per_adult_per_night" IS 'Local tourist tax, children usually exempt';

COMMENT ON COLUMN "hotels"."is_active" IS 'Temporarily unbookable even if PUBLISHED';

COMMENT ON COLUMN "hotels"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "hotels"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN "hotels"."deleted_at" IS 'Soft delete: NULL = live row';

COMMENT ON TABLE "hotel_staff" IS 'Which HOTEL_MANAGER user can manage which hotel. Checked in @PreAuthorize';

COMMENT ON COLUMN "hotel_staff"."deleted_at" IS 'Soft delete: NULL = still works there';

COMMENT ON COLUMN "hotel_images"."object_key" IS 'Key in MinIO/S3 bucket, not a full URL';

COMMENT ON COLUMN "amenities"."code" IS 'WIFI, POOL, PARKING, AIR_CONDITIONING...';

COMMENT ON COLUMN "amenities"."icon" IS 'Icon name for a future frontend';

COMMENT ON COLUMN "rooms"."room_number" IS 'Unique within a hotel among non-deleted rooms';

COMMENT ON COLUMN "rooms"."base_price_per_night" IS 'In hotels.currency. Fallback when no room_rates row exists';

COMMENT ON COLUMN "rooms"."is_active" IS 'Out of service indefinitely. Date ranges -> room_blocks';

COMMENT ON COLUMN "rooms"."version" IS 'JPA @Version for admin edits. Booking uses PESSIMISTIC_WRITE on this row';

COMMENT ON COLUMN "rooms"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "rooms"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN "rooms"."deleted_at" IS 'Soft delete: NULL = live row';

COMMENT ON TABLE "room_blocks" IS 'Creating a block must also lock the room row and reject if it overlaps an active booking';

COMMENT ON COLUMN "room_blocks"."end_date" IS 'Exclusive, same convention as check_out_date. CHECK (end_date > start_date)';

COMMENT ON COLUMN "room_blocks"."reason" IS 'Renovation, maintenance, owner use...';

COMMENT ON COLUMN "room_blocks"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "room_blocks"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN "room_blocks"."deleted_at" IS 'Soft delete = block lifted';

COMMENT ON COLUMN "room_images"."object_key" IS 'Key in MinIO/S3 bucket';

COMMENT ON TABLE "room_rates" IS 'Seasonal / weekend pricing per room type. Total = sum of nights, falling back to rooms.base_price_per_night';

COMMENT ON COLUMN "room_rates"."stay_date" IS 'One row per night';

COMMENT ON COLUMN "room_rates"."price_per_night" IS 'In hotels.currency';

COMMENT ON COLUMN "room_rates"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "room_rates"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON TABLE "services" IS 'Global catalog. No price here - each hotel sets its own in hotel_services';

COMMENT ON COLUMN "services"."code" IS 'BREAKFAST, HALF_BOARD, FULL_BOARD, ALL_INCLUSIVE...';

COMMENT ON COLUMN "services"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "services"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN "services"."deleted_at" IS 'Soft delete: NULL = live row';

COMMENT ON COLUMN "hotel_services"."price_per_person_per_night" IS 'In hotels.currency';

COMMENT ON COLUMN "hotel_services"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "hotel_services"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN "hotel_services"."deleted_at" IS 'Soft delete: NULL = live row';

COMMENT ON TABLE "promo_codes" IS 'Per-user usage = COUNT(bookings WHERE user_id AND promo_code_id AND status NOT IN (CANCELLED, EXPIRED))';

COMMENT ON COLUMN "promo_codes"."code" IS 'Store upper-cased, e.g. SUMMER26';

COMMENT ON COLUMN "promo_codes"."hotel_id" IS 'NULL = valid on every hotel (platform promo, ADMIN only)';

COMMENT ON COLUMN "promo_codes"."discount_value" IS 'Percent (0-100) or fixed amount';

COMMENT ON COLUMN "promo_codes"."max_discount_amount" IS 'Cap for PERCENT codes';

COMMENT ON COLUMN "promo_codes"."max_uses" IS 'NULL = unlimited';

COMMENT ON COLUMN "promo_codes"."used_count" IS 'Incremented under PESSIMISTIC_WRITE lock on this row';

COMMENT ON COLUMN "promo_codes"."created_by" IS 'Spring Data @CreatedBy';

COMMENT ON COLUMN "promo_codes"."updated_by" IS 'Spring Data @LastModifiedBy';

COMMENT ON COLUMN "promo_codes"."deleted_at" IS 'Soft delete: NULL = live row';

COMMENT ON TABLE "bookings" IS 'Never deleted, only CANCELLED/EXPIRED (audit/financial history)';

COMMENT ON COLUMN "bookings"."reference" IS 'Human-friendly code, e.g. BK7F3K9Q';

COMMENT ON COLUMN "bookings"."user_id" IS 'Account that booked and pays';

COMMENT ON COLUMN "bookings"."hotel_service_id" IS 'NULL = room only';

COMMENT ON COLUMN "bookings"."guest_first_name" IS 'Who actually stays; defaults to the user';

COMMENT ON COLUMN "bookings"."check_out_date" IS 'CHECK (check_out_date > check_in_date)';

COMMENT ON COLUMN "bookings"."expires_at" IS 'Only for PENDING: hold ends here';

COMMENT ON COLUMN "bookings"."room_price_total" IS 'Snapshot at booking time';

COMMENT ON COLUMN "bookings"."service_price_total" IS 'Snapshot';

COMMENT ON COLUMN "bookings"."discount_total" IS 'From promo code';

COMMENT ON COLUMN "bookings"."tax_total" IS 'Tourist tax: adults x nights x hotel rate';

COMMENT ON COLUMN "bookings"."total_price" IS 'room + service - discount + tax';

COMMENT ON COLUMN "bookings"."currency" IS 'Snapshot of hotels.currency';

COMMENT ON COLUMN "bookings"."free_cancellation_until" IS 'Computed in hotel timezone, stored as UTC instant';

COMMENT ON COLUMN "bookings"."late_cancellation_fee_percent" IS 'Snapshot of hotel policy';

COMMENT ON COLUMN "bookings"."version" IS 'JPA @Version: confirm vs cancel race';

COMMENT ON COLUMN "booking_status_history"."from_status" IS 'NULL for the initial PENDING';

COMMENT ON COLUMN "booking_status_history"."changed_by" IS 'NULL = system (expiry job, payment webhook)';

COMMENT ON COLUMN "payments"."amount" IS 'Always positive, type says direction';

COMMENT ON COLUMN "payments"."provider" IS 'MOCK, STRIPE...';

COMMENT ON COLUMN "payments"."provider_reference" IS 'ID from the provider, set after the call';

COMMENT ON COLUMN "payments"."idempotency_key" IS 'Prevents double charge on retries';

COMMENT ON COLUMN "payments"."refunded_payment_id" IS 'For REFUND rows: which CHARGE it refunds';

COMMENT ON TABLE "reviews" IS 'Average rating + count cached in Redis per hotel, evicted on new review';

COMMENT ON COLUMN "reviews"."booking_id" IS 'One review per stay, only if booking is COMPLETED';

COMMENT ON COLUMN "reviews"."hotel_id" IS 'Denormalized from booking for fast per-hotel queries';

COMMENT ON COLUMN "reviews"."rating" IS 'CHECK 1-10, like Booking.com';

COMMENT ON COLUMN "reviews"."hotel_response" IS 'Reply from hotel staff';

COMMENT ON COLUMN "reviews"."deleted_at" IS 'Soft delete, e.g. moderation';

COMMENT ON TABLE "emails" IS 'Transactional outbox: inserted in the same DB transaction as the booking, sent by a @Scheduled worker';

COMMENT ON COLUMN "emails"."user_id" IS 'NULL for non-user recipients';

COMMENT ON COLUMN "emails"."booking_id" IS 'Context, e.g. confirmation or reminder';

COMMENT ON COLUMN "emails"."template" IS 'BOOKING_CONFIRMED, CHECK_IN_REMINDER, VERIFY_EMAIL, HOTEL_APPROVED...';

COMMENT ON COLUMN "emails"."payload" IS 'Template variables; rendered at send time';

COMMENT ON COLUMN "emails"."scheduled_at" IS 'now() = ASAP, future = scheduled';

COMMENT ON COLUMN "emails"."dedup_key" IS 'e.g. CHECK_IN_REMINDER:<booking_id>, prevents duplicates';

ALTER TABLE "login_logs" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "favorites" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "favorites" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotels" ADD FOREIGN KEY ("approved_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotels" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotels" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_staff" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_staff" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_staff" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_images" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_images" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_amenities" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_amenities" ADD FOREIGN KEY ("amenity_id") REFERENCES "amenities" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "rooms" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "rooms" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "rooms" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_blocks" ADD FOREIGN KEY ("room_id") REFERENCES "rooms" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_blocks" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_blocks" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_images" ADD FOREIGN KEY ("room_id") REFERENCES "rooms" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_images" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_amenities" ADD FOREIGN KEY ("room_id") REFERENCES "rooms" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_amenities" ADD FOREIGN KEY ("amenity_id") REFERENCES "amenities" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_rates" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_rates" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "room_rates" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "services" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "services" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_services" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_services" ADD FOREIGN KEY ("service_id") REFERENCES "services" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_services" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "hotel_services" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("created_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "promo_codes" ADD FOREIGN KEY ("updated_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("room_id") REFERENCES "rooms" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("hotel_service_id") REFERENCES "hotel_services" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "bookings" ADD FOREIGN KEY ("promo_code_id") REFERENCES "promo_codes" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "booking_status_history" ADD FOREIGN KEY ("booking_id") REFERENCES "bookings" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "booking_status_history" ADD FOREIGN KEY ("changed_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "payments" ADD FOREIGN KEY ("booking_id") REFERENCES "bookings" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "payments" ADD FOREIGN KEY ("refunded_payment_id") REFERENCES "payments" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("booking_id") REFERENCES "bookings" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("hotel_id") REFERENCES "hotels" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "reviews" ADD FOREIGN KEY ("responded_by") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "emails" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "emails" ADD FOREIGN KEY ("booking_id") REFERENCES "bookings" ("id") DEFERRABLE INITIALLY IMMEDIATE;
