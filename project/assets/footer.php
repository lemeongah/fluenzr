<?php
/**
 * The template for displaying the footer.
 *
 * @package GeneratePress Child
 */

if (!defined('ABSPATH')) {
	exit; // Exit if accessed directly.
}
?>
</div><!-- #content -->
</div><!-- #page -->

<?php
/**
 * generate_before_footer hook.
 *
 * @since 0.1
 */
do_action('generate_before_footer');

/**
 * generate_footer hook.
 *
 * @since 0.1
 *
 * @hooked generate_construct_footer_widgets - 5
 * @hooked generate_construct_footer - 10
 */
do_action('generate_footer');

/**
 * generate_after_footer hook.
 *
 * @since 0.1
 */
do_action('generate_after_footer');
?>

<?php wp_footer(); ?>
</body>
</html>