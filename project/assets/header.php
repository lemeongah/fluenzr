<?php
/**
 * The header for our theme.
 *
 * @package GeneratePress Child
 */

if (!defined('ABSPATH')) {
    exit; // Exit if accessed directly.
}

?><!DOCTYPE html>
<html <?php language_attributes(); ?>>

<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="profile" href="https://gmpg.org/xfn/11">
    <?php wp_head(); ?>
    <script src="https://unpkg.com/css-doodle@0.15.3/css-doodle.min.js"></script>
</head>
<script type="text/javascript" src="https://s.skimresources.com/js/292380X1779517.skimlinks.js"></script>

<script>
document.addEventListener('DOMContentLoaded', function () {
  const ul = document.querySelector('.home-mosaic.wp-block-latest-posts.is-grid');
  if (!ul || window.innerWidth <= 1000) return;
  const items = Array.from(ul.children);
  if (items.length === 0) return;

  const patterns = [
    [3],[2,1],[1,1,1],[1,2],[1,1,1],
  ];
  let currentIndex = 0;
  let previousPattern = -1;

  if (items.length > 0) {
    const firstItem = items[0];
    firstItem.classList.remove('wide','tall','single-normal');
    firstItem.classList.add('full-width');
    currentIndex = 1;
  }

  function getNextPattern() {
    let nextPattern;
    do {
      const available = patterns.slice(1);
      nextPattern = Math.floor(Math.random() * available.length) + 1;
    } while (nextPattern === previousPattern && patterns.length > 2);
    previousPattern = nextPattern;
    return patterns[nextPattern];
  }

  while (currentIndex < items.length) {
    const currentPattern = getNextPattern();
    let used = 0;
    const rowItems = [];
    for (let i = 0; i < currentPattern.length && currentIndex < items.length; i++) {
      const item = items[currentIndex];
      const size = currentPattern[i];
      item.classList.remove('wide','tall','single-normal','full-width');
      if (size === 3) { item.classList.add('full-width'); used += 3; }
      else if (size === 2) { item.classList.add('wide'); used += 2; }
      else { used += 1; }
      rowItems.push({item,size});
      currentIndex++;
      if (used >= 3) break;
    }
    const normalCards = rowItems.filter(r => r.size === 1);
    if (normalCards.length === 1) normalCards[0].item.classList.add('single-normal');
  }

  // --- PATCH FULL-WIDTH : regrouper titre + excerpt dans .full-width-content ---
  document.querySelectorAll('.home-mosaic li.full-width').forEach(card => {
    const hasWrapper = card.querySelector(':scope > .full-width-content');
    if (!hasWrapper) {
      const title = card.querySelector(':scope > .wp-block-latest-posts__post-title');
      const excerpt = card.querySelector(':scope > .wp-block-latest-posts__post-excerpt');
      if (title) {
        const wrapper = document.createElement('div');
        wrapper.className = 'full-width-content';
        // Insérer le wrapper après l'image si elle existe
        const imgBlock = card.querySelector(':scope > .wp-block-latest-posts__featured-image');
        if (imgBlock && imgBlock.nextSibling) {
          card.insertBefore(wrapper, imgBlock.nextSibling);
        } else {
          card.appendChild(wrapper);
        }
        wrapper.appendChild(title);
        if (excerpt) wrapper.appendChild(excerpt);
      }
    }
  });
  // ---------------------------------------------------------------------------

  console.log('Mosaic ok + regroupement full-width');
});
</script>


<body <?php body_class(); ?>>
    <?php
    /**
     * wp_body_open hook.
     *
     * @since 2.3
     */
    do_action('wp_body_open');
    ?>


    <div id="page" class="hfeed site">
        <?php
        /**
         * generate_before_header hook.
         *
         * @since 0.1
         */
        do_action('generate_before_header');

        /**
         * generate_header hook.
         *
         * @since 1.3.42
         *
         * @hooked generate_construct_header - 10
         */
        do_action('generate_header');

        /**
         * generate_after_header hook.
         *
         * @since 0.1
         */
        do_action('generate_after_header');
        ?>

        <div id="content" class="site-content">
            <?php
            /**
             * generate_inside_container hook.
             *
             * @since 0.1
             */
            do_action('generate_inside_container');
            ?>
