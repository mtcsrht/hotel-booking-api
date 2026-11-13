package com.hotelbooking.api.config;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.time.Instant;

import javax.crypto.spec.SecretKeySpec;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(properties = "app.jwt.secret=test-only-secret-at-least-32-bytes-long")
@Import(SecurityConfig.class)
class SecurityConfigTests {

	@Autowired
	MockMvc mvc;

	@Autowired
	JwtEncoder encoder;

	@Test
	void rejectsMissingToken() throws Exception {
		mvc.perform(get("/anything")).andExpect(status().isUnauthorized());
	}

	@Test
	void acceptsValidToken() throws Exception {
		String token = sign(encoder, Instant.now().plusSeconds(60));
		// 404, not 401: the request got past security and found no controller.
		mvc.perform(get("/anything").header("Authorization", "Bearer " + token)).andExpect(status().isNotFound());
	}

	@Test
	void rejectsExpiredToken() throws Exception {
		String token = sign(encoder, Instant.now().minusSeconds(3600));
		mvc.perform(get("/anything").header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
	}

	@Test
	void rejectsTokenSignedWithOtherKey() throws Exception {
		byte[] otherSecret = "another-secret-also-at-least-32-bytes-long".getBytes(StandardCharsets.UTF_8);
		JwtEncoder other = NimbusJwtEncoder.withSecretKey(new SecretKeySpec(otherSecret, "HmacSHA256")).build();
		String token = sign(other, Instant.now().plusSeconds(60));
		mvc.perform(get("/anything").header("Authorization", "Bearer " + token)).andExpect(status().isUnauthorized());
	}

	@Test
	void refusesToStartWithShortSecret() {
		assertThatThrownBy(() -> new SecurityConfig().jwtSecretKey("too-short"))
			.isInstanceOf(IllegalStateException.class)
			.hasMessageNotContaining("too-short");
	}

	private static String sign(JwtEncoder encoder, Instant expiresAt) {
		JwtClaimsSet claims = JwtClaimsSet.builder()
			.subject("guest")
			.issuedAt(expiresAt.minusSeconds(60))
			.expiresAt(expiresAt)
			.build();
		return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
			.getTokenValue();
	}

}
