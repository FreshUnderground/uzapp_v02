<?php
/**
 * Root delegate for /product/{id} rewrites on legacy LWS deployments.
 * Forwards to the canonical landing page in /api/.
 */
require __DIR__ . '/api/product_page.php';
