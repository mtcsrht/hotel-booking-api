CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  email varchar(255) NOT NULL,
  password_hash varchar(255) NOT NULL,
  first_name varchar(100) NOT NULL,
  last_name varchar(100) NOT NULL,
  phone varchar(30),
  role user_role NOT NULL DEFAULT 'GUEST',
  email_verified_at timestamptz,
  failed_login_attempts smallint NOT NULL DEFAULT 0,
  locked_until timestamptz,
  last_login_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT users_email_lowercase CHECK (email = lower(email))
);

CREATE TABLE login_logs (
  id bigserial PRIMARY KEY,
  user_id uuid,
  email_attempted varchar(255) NOT NULL,
  result login_result NOT NULL,
  ip_address inet NOT NULL,
  user_agent varchar(512),
  country_code char(2),
  city varchar(100),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE favorites (
  user_id uuid NOT NULL,
  hotel_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, hotel_id)
);

CREATE TABLE hotels (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  name varchar(150) NOT NULL,
  description text,
  status hotel_status NOT NULL DEFAULT 'DRAFT',
  rejection_reason varchar(500),
  approved_by uuid,
  approved_at timestamptz,
  star_rating smallint,
  address_line varchar(255) NOT NULL,
  city varchar(100) NOT NULL,
  country_code char(2) NOT NULL,
  postal_code varchar(20),
  latitude decimal(9,6),
  longitude decimal(9,6),
  timezone varchar(50) NOT NULL,
  currency char(3) NOT NULL DEFAULT 'EUR',
  check_in_from time NOT NULL DEFAULT '14:00',
  check_out_until time NOT NULL DEFAULT '11:00',
  free_cancellation_hours smallint NOT NULL DEFAULT 48,
  late_cancellation_fee_percent smallint NOT NULL DEFAULT 100,
  tourist_tax_per_adult_per_night decimal(10,2) NOT NULL DEFAULT 0,
  contact_email varchar(255),
  contact_phone varchar(30),
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT hotels_star_rating_range CHECK (star_rating BETWEEN 1 AND 5),
  CONSTRAINT hotels_late_fee_range CHECK (late_cancellation_fee_percent BETWEEN 0 AND 100)
);

CREATE TABLE hotel_staff (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  user_id uuid NOT NULL,
  hotel_id uuid NOT NULL,
  staff_role staff_role NOT NULL DEFAULT 'MANAGER',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE hotel_images (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  hotel_id uuid NOT NULL,
  object_key varchar(500) NOT NULL,
  alt_text varchar(255),
  sort_order smallint NOT NULL DEFAULT 0,
  is_cover boolean NOT NULL DEFAULT false,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE amenities (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  code varchar(40) UNIQUE NOT NULL,
  name varchar(100) NOT NULL,
  scope amenity_scope NOT NULL,
  icon varchar(50)
);

CREATE TABLE hotel_amenities (
  hotel_id uuid NOT NULL,
  amenity_id uuid NOT NULL,
  PRIMARY KEY (hotel_id, amenity_id)
);

CREATE TABLE rooms (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  hotel_id uuid NOT NULL,
  room_number varchar(10) NOT NULL,
  type room_type NOT NULL,
  floor smallint,
  max_occupancy smallint NOT NULL,
  bed_count smallint NOT NULL DEFAULT 1,
  size_sqm decimal(6,2),
  base_price_per_night decimal(10,2) NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  version integer NOT NULL DEFAULT 0,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE room_blocks (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  room_id uuid NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  reason varchar(255),
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT room_blocks_date_order CHECK (end_date > start_date)
);

CREATE TABLE room_images (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  room_id uuid NOT NULL,
  object_key varchar(500) NOT NULL,
  alt_text varchar(255),
  sort_order smallint NOT NULL DEFAULT 0,
  is_cover boolean NOT NULL DEFAULT false,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE room_amenities (
  room_id uuid NOT NULL,
  amenity_id uuid NOT NULL,
  PRIMARY KEY (room_id, amenity_id)
);

CREATE TABLE room_rates (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  hotel_id uuid NOT NULL,
  room_type room_type NOT NULL,
  stay_date date NOT NULL,
  price_per_night decimal(10,2) NOT NULL,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE services (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  code varchar(30) UNIQUE NOT NULL,
  name varchar(100) NOT NULL,
  description text,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE hotel_services (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  hotel_id uuid NOT NULL,
  service_id uuid NOT NULL,
  price_per_person_per_night decimal(10,2) NOT NULL,
  is_available boolean NOT NULL DEFAULT true,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE TABLE promo_codes (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  code varchar(30) UNIQUE NOT NULL,
  hotel_id uuid,
  discount_type discount_type NOT NULL,
  discount_value decimal(10,2) NOT NULL,
  max_discount_amount decimal(10,2),
  min_nights smallint NOT NULL DEFAULT 1,
  valid_from timestamptz NOT NULL,
  valid_until timestamptz NOT NULL,
  max_uses integer,
  used_count integer NOT NULL DEFAULT 0,
  max_uses_per_user smallint NOT NULL DEFAULT 1,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT promo_codes_code_uppercase CHECK (code = upper(code)),
  CONSTRAINT promo_codes_percent_range CHECK (discount_type <> 'PERCENT' OR discount_value BETWEEN 0 AND 100)
);

CREATE TABLE bookings (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  reference varchar(12) UNIQUE NOT NULL,
  user_id uuid NOT NULL,
  room_id uuid NOT NULL,
  hotel_service_id uuid,
  promo_code_id uuid,
  guest_first_name varchar(100) NOT NULL,
  guest_last_name varchar(100) NOT NULL,
  check_in_date date NOT NULL,
  check_out_date date NOT NULL,
  adults smallint NOT NULL DEFAULT 1,
  children smallint NOT NULL DEFAULT 0,
  status booking_status NOT NULL DEFAULT 'PENDING',
  expires_at timestamptz,
  room_price_total decimal(10,2) NOT NULL,
  service_price_total decimal(10,2) NOT NULL DEFAULT 0,
  discount_total decimal(10,2) NOT NULL DEFAULT 0,
  tax_total decimal(10,2) NOT NULL DEFAULT 0,
  total_price decimal(10,2) NOT NULL,
  currency char(3) NOT NULL,
  free_cancellation_until timestamptz NOT NULL,
  late_cancellation_fee_percent smallint NOT NULL,
  special_requests text,
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason varchar(500),
  version integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT bookings_no_overlap EXCLUDE USING gist (
    room_id WITH =,
    daterange(check_in_date, check_out_date) WITH &&
  ) WHERE (status IN ('PENDING', 'CONFIRMED')),
  CONSTRAINT bookings_date_order CHECK (check_out_date > check_in_date),
  CONSTRAINT bookings_late_fee_range CHECK (late_cancellation_fee_percent BETWEEN 0 AND 100),
  CONSTRAINT bookings_total_price CHECK (total_price = room_price_total + service_price_total - discount_total + tax_total)
);

CREATE TABLE booking_status_history (
  id bigserial PRIMARY KEY,
  booking_id uuid NOT NULL,
  from_status booking_status,
  to_status booking_status NOT NULL,
  changed_by uuid,
  reason varchar(500),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE payments (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  booking_id uuid NOT NULL,
  type payment_type NOT NULL DEFAULT 'CHARGE',
  status payment_status NOT NULL DEFAULT 'INITIATED',
  amount decimal(10,2) NOT NULL,
  currency char(3) NOT NULL,
  provider varchar(30) NOT NULL,
  provider_reference varchar(100) UNIQUE,
  idempotency_key varchar(64) UNIQUE NOT NULL,
  failure_reason varchar(500),
  refunded_payment_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT payments_amount_positive CHECK (amount > 0),
  CONSTRAINT payments_refund_link CHECK ((type = 'REFUND') = (refunded_payment_id IS NOT NULL))
);

CREATE TABLE reviews (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  booking_id uuid UNIQUE NOT NULL,
  user_id uuid NOT NULL,
  hotel_id uuid NOT NULL,
  rating smallint NOT NULL,
  title varchar(150),
  comment text,
  hotel_response text,
  responded_by uuid,
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT reviews_rating_range CHECK (rating BETWEEN 1 AND 10)
);

CREATE TABLE emails (
  id uuid PRIMARY KEY DEFAULT uuidv7(),
  user_id uuid,
  booking_id uuid,
  to_address varchar(255) NOT NULL,
  template varchar(50) NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}',
  status email_status NOT NULL DEFAULT 'PENDING',
  scheduled_at timestamptz NOT NULL DEFAULT now(),
  attempts smallint NOT NULL DEFAULT 0,
  last_error text,
  sent_at timestamptz,
  dedup_key varchar(150) UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
