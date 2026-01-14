<?php
/**
 * Functions.php pour GeneratePress Child Theme
 * Family UGC
 * Ce fichier est intelligent et s'adapte automatiquement à l'environnement (local/production)
 */

// ========================================
// SEO: GESTION DES URLs MALFORMÉES (410 Gone)
// ========================================
// Retourne 410 Gone pour les URLs avec guillemets (erreurs de parsing WordPress)
// Ces URLs n'ont jamais existé et doivent être désindexées rapidement par Google
add_action('template_redirect', 'handle_malformed_urls', 1);
function handle_malformed_urls() {
    $request_uri = $_SERVER['REQUEST_URI'] ?? '';

    // Patterns d'URLs malformées à bloquer avec 410 Gone
    $malformed_patterns = [
        // URLs avec guillemets imbriqués (erreurs de contenu WordPress)
        '/^\/?"http/',
        '/^\/["\']/',
        '/\/"https?:/',
        // Fichiers internes exposés par erreur
        '/\/wp-content\/themes\/.*\.php$/',
        '/\/wp-content\/plugins\/.*\.php$/',
    ];

    foreach ($malformed_patterns as $pattern) {
        if (preg_match($pattern, $request_uri)) {
            status_header(410);
            nocache_headers();
            echo '410 Gone - This page has been permanently removed';
            exit;
        }
    }
}

/**
 * INJECT META DESCRIPTIONS DIRECTLY
 * Injecte directement les meta descriptions dans le <head>
 * pour que Google les voie, sans dépendre de RankMath
 */
add_action('wp_head', 'inject_meta_description', 1);
function inject_meta_description() {
    if (!is_singular('post')) {
        return;
    }

    $post_id = get_the_ID();

    // 1. Essayer de récupérer depuis rank_math_description
    $description = get_post_meta($post_id, 'rank_math_description', true);

    // 2. Si pas trouvé, essayer depuis l'excerpt
    if (empty($description)) {
        $post = get_post($post_id);
        $description = $post->post_excerpt;
    }

    // 3. Si toujours pas trouvé, générer depuis le contenu (160 chars)
    if (empty($description)) {
        $post = get_post($post_id);
        $description = substr(strip_tags($post->post_content), 0, 160);
        if (strlen(strip_tags($post->post_content)) > 160) {
            $description .= '...';
        }
    }

    // Afficher la balise meta description
    if (!empty($description)) {
        echo '<meta name="description" content="' . esc_attr($description) . '" />' . "\n";
    }
}

// Détection de l'environnement
function is_production()
{
    // Vérifie si l'URL du site correspond à l'URL de production définie dans .env
    $site_url = site_url();
    $prod_url = getenv('PROD_URL') ?: '';

    if (!empty($prod_url)) {
        $prod_domain = parse_url($prod_url, PHP_URL_HOST);
        return (strpos($site_url, $prod_domain) !== false);
    }

    // Fallback: considérer comme production si ce n'est pas localhost
    return (strpos($site_url, 'localhost') === false && strpos($site_url, '127.0.0.1') === false);
}

// ========================================
// AUGMENTER LES LIMITES D'UPLOAD
// ========================================
// Augmenter la limite d'upload à 100MB (vs 2MB par défaut)
// Note: Le Dockerfile est configuré avec 64M, on augmente à 100M ici
@ini_set('upload_max_filesize', '100M');
@ini_set('post_max_size', '100M');
@ini_set('memory_limit', '512M');

// Filtre WordPress pour augmenter la taille max de fichier uploadable
add_filter('upload_size_limit', 'increase_upload_size_limit');
function increase_upload_size_limit($size)
{
    // Retourner 100MB en bytes (100 * 1024 * 1024)
    return 100 * 1024 * 1024;
}

// Ajouter le support du logo personnalisé depuis les assets
add_action('after_setup_theme', 'theme_setup');
function theme_setup()
{
    add_theme_support('custom-logo', array(
        'height'      => 60,
        'width'       => 200,
        'flex-height' => true,
        'flex-width'  => true,
    ));
    add_theme_support('site-icon');
}

// Afficher le logo directement depuis les assets en remplaçant le site-branding
add_filter('wp_nav_menu_items', 'prepend_logo_to_nav', 10, 2);
function prepend_logo_to_nav($items, $args)
{
    // Vérifier si c'est le menu principal
    if ($args->theme_location !== 'primary') {
        return $items;
    }

    // Vérifier si logo.png existe dans les assets
    $logo_path = '/wp-content/uploads/custom/logo.png';
    $file_path = ABSPATH . 'wp-content/uploads/custom/logo.png';

    if (!file_exists($file_path)) {
        return $items;
    }

    $site_url = home_url();
    $site_name = get_bloginfo('name');
    $logo_url = $site_url . $logo_path;

    $logo_html = '<div class="site-logo" style="display: inline-block; margin-right: auto;">';
    $logo_html .= '<a href="' . esc_url($site_url) . '" class="custom-logo-link" title="' . esc_attr($site_name) . '">';
    $logo_html .= '<img src="' . esc_url($logo_url) . '" alt="' . esc_attr($site_name) . '" class="header-image is-logo-image" style="height: auto; max-width: 280px;" />';
    $logo_html .= '</a></div>';

    return $logo_html . $items;
}

// Enregistrer le thème parent et les styles personnalisés
add_action('wp_enqueue_scripts', 'theme_enqueue_styles');
function theme_enqueue_styles()
{
    // Toujours charger le style parent
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
     wp_enqueue_style(
            'site-vars',
            get_stylesheet_directory_uri() . '/style.css',
            [],
            '1.0.0'
        );

        // 2) CSS partagé depuis le CDN (toujours la dernière version)
        // $ver = false => pas de ?ver=, on se repose sur must-revalidate (ETag/Last-Modified)
        wp_enqueue_style(
            'lemeon-shared',
            'https://static.le-meon.com/css/shared.css',
            ['site-vars'],
            false
        );

    // Charger le design Fluenzr personnalisé
    wp_enqueue_style(
        'fluenzr-design',
        get_stylesheet_directory_uri() . '/fluenzr-design.css',
        ['site-vars'],
        '1.0.2'
    );

    // Utiliser le bon chemin selon l'environnement
    if (is_production()) {
        // En production, utiliser des URLs absolues pour éviter les problèmes mixtes HTTP/HTTPS
        $site_url = site_url();
        wp_enqueue_style('custom-style', $site_url . '/wp-content/uploads/custom/css/styles.css', array(), '1.0.3');
        // Charger les styles de mosaïque séparément
        wp_enqueue_style('mosaic-style', $site_url . '/wp-content/uploads/custom/mosaic-styles.css', array('custom-style'), '1.0.1');
    } else {
        // En local, utiliser des chemins relatifs standards
        wp_enqueue_style('custom-style', '/wp-content/uploads/custom/css/styles.css', array(), '1.0.3');
        // Charger les styles de mosaïque séparément
        wp_enqueue_style('mosaic-style', '/wp-content/uploads/custom/mosaic-styles.css', array('custom-style'), '1.0.1');
    }
}

// JavaScript pour gérer les clics sur les cartes wide et full-width
add_action('wp_footer', 'add_mosaic_click_handler');
function add_mosaic_click_handler() {
    ?>
    <script>
    document.addEventListener('DOMContentLoaded', function() {
        // Vérifier si on est sur la page d'accueil
        const isHomePage = document.body.classList.contains('home') ||
                          document.body.classList.contains('blog') ||
                          window.location.pathname === '/' ||
                          window.location.pathname === '/index.php';

        // Gérer les clics sur les cartes wide
        const wideCards = document.querySelectorAll('.home-mosaic li.wide');
        wideCards.forEach(function(card) {
            const titleLink = card.querySelector('.wp-block-latest-posts__post-title');
            if (titleLink && titleLink.href) {
                // Ajouter un gestionnaire de clic sur toute la carte
                card.addEventListener('click', function(e) {
                    // Ne pas déclencher si on clique directement sur le titre
                    if (e.target === titleLink || titleLink.contains(e.target)) {
                        return;
                    }
                    window.location.href = titleLink.href;
                });
                card.style.cursor = 'pointer';
            }
        });

        // Optimisation : traiter les cartes full-width de manière plus efficace
        const fullWidthCards = document.querySelectorAll('.home-mosaic li.full-width');

        if (fullWidthCards.length === 0) {
            console.log('🎨 Aucune carte full-width trouvée');
            return;
        }

        // Fonction optimisée pour récupérer la catégorie
        function getPostCategoryOptimized(postUrl, callback) {
            // Cache pour éviter les requêtes répétées
            if (window.categoryCache && window.categoryCache[postUrl]) {
                callback(window.categoryCache[postUrl]);
                return;
            }

            if (!window.categoryCache) {
                window.categoryCache = {};
            }

            // Extraire l'ID du post depuis l'URL
            const postId = postUrl.match(/\?p=(\d+)/);
            if (postId) {
                // Utiliser l'API REST WordPress
                fetch('/wp-json/wp/v2/posts/' + postId[1] + '?_fields=categories')
                    .then(response => response.json())
                    .then(data => {
                        if (data.categories && data.categories.length > 0) {
                            fetch('/wp-json/wp/v2/categories/' + data.categories[0] + '?_fields=name')
                                .then(response => response.json())
                                .then(categoryData => {
                                    window.categoryCache[postUrl] = categoryData.name;
                                    callback(categoryData.name);
                                })
                                .catch(() => {
                                    window.categoryCache[postUrl] = 'Article';
                                    callback('Article');
                                });
                        } else {
                            window.categoryCache[postUrl] = 'Article';
                            callback('Article');
                        }
                    })
                    .catch(() => {
                        window.categoryCache[postUrl] = 'À la une';
                        callback('À la une');
                    });
            } else {
                // Essayer avec pretty permalinks
                const slug = postUrl.split('/').filter(part => part.length > 0).pop();
                fetch('/wp-json/wp/v2/posts?slug=' + slug + '&_fields=categories')
                    .then(response => response.json())
                    .then(data => {
                        if (data.length > 0 && data[0].categories && data[0].categories.length > 0) {
                            fetch('/wp-json/wp/v2/categories/' + data[0].categories[0] + '?_fields=name')
                                .then(response => response.json())
                                .then(categoryData => {
                                    window.categoryCache[postUrl] = categoryData.name;
                                    callback(categoryData.name);
                                })
                                .catch(() => {
                                    window.categoryCache[postUrl] = 'Article';
                                    callback('Article');
                                });
                        } else {
                            window.categoryCache[postUrl] = 'À la une';
                            callback('À la une');
                        }
                    })
                    .catch(() => {
                        window.categoryCache[postUrl] = 'À la une';
                        callback('À la une');
                    });
            }
        }

        // Traitement optimisé des cartes full-width
        fullWidthCards.forEach(function(card, index) {
            const titleLink = card.querySelector('.wp-block-latest-posts__post-title');
            const featuredImage = card.querySelector('.wp-block-latest-posts__featured-image');
            const excerpt = card.querySelector('.wp-block-latest-posts__post-excerpt');

            if (!titleLink || !featuredImage) {
                console.warn('⚠️ Carte full-width incomplète détectée, ignorée');
                return;
            }

            card.classList.add('restructuring');

            const titleText = titleLink.textContent;
            const titleHref = titleLink.href;
            const excerptText = excerpt ? excerpt.textContent : '';

            function finalizeRestructuring(categoryName) {
                requestAnimationFrame(() => {
                    // Cloner l'image
                    const imageContainer = featuredImage.cloneNode(true);

                    // Créer le conteneur de contenu (colonne de droite)
                    const contentDiv = document.createElement('div');
                    contentDiv.className = 'full-width-content';

                    // Ajouter la catégorie en tag (ordre 1)
                    if (categoryName) {
                        const categoryTag = document.createElement('a');
                        categoryTag.className = 'post-category';
                        categoryTag.textContent = categoryName;
                        categoryTag.href = '#';
                        contentDiv.appendChild(categoryTag);
                    }

                    // Titre (ordre 2) - AU-DESSUS de l'excerpt dans le même conteneur
                    const newTitle = document.createElement('a');
                    newTitle.className = 'wp-block-latest-posts__post-title';
                    newTitle.href = titleHref;
                    newTitle.textContent = titleText;
                    contentDiv.appendChild(newTitle);

                    // Extrait (ordre 3) - EN-DESSOUS du titre dans le même conteneur
                    if (excerptText.trim()) {
                        const newExcerpt = document.createElement('div');
                        newExcerpt.className = 'wp-block-latest-posts__post-excerpt';
                        newExcerpt.textContent = excerptText;
                        contentDiv.appendChild(newExcerpt);
                    }

                    // IMPORTANT: Reconstruction en 2 colonnes seulement
                    // 1. Image (50% gauche)
                    // 2. Tout le contenu (50% droite)
                    card.innerHTML = '';
                    card.appendChild(imageContainer);
                    card.appendChild(contentDiv);

                    // Gestionnaire de clic
                    card.addEventListener('click', function(e) {
                        if (e.target.tagName === 'A' || e.target.closest('a')) {
                            return;
                        }
                        window.location.href = titleHref;
                    });

                    card.style.cursor = 'pointer';
                    card.classList.remove('restructuring');
                    card.classList.add('restructured');
                });
            }

            // Récupérer la catégorie et restructurer
            getPostCategoryOptimized(titleHref, finalizeRestructuring);
        });

        // === Patch simple: créer le conteneur .full-width-content si absent ===
        document.querySelectorAll('.home-mosaic li.full-width').forEach(function(card){
            if (!card.querySelector('.full-width-content')) {
                const title = card.querySelector(':scope > .wp-block-latest-posts__post-title');
                const excerpt = card.querySelector(':scope > .wp-block-latest-posts__post-excerpt');
                if (title) {
                    const wrap = document.createElement('div');
                    wrap.className = 'full-width-content';
                    card.appendChild(wrap);
                    wrap.appendChild(title);
                    if (excerpt) wrap.appendChild(excerpt);
                }
            }
        });

        console.log('🎨 Restructuration optimisée des', fullWidthCards.length, 'cartes full-width');
    });
    </script>
    <?php
}

// ========================================
// GOOGLE ANALYTICS (GTAG)
// ========================================
// Configuration: Ajouter GTAG_ID dans votre fichier .env
// Exemple: GTAG_ID=G-XXXXXXXXXX
function add_google_analytics()
{
    // Récupérer l'ID de mesure depuis la variable d'environnement
    $measurement_id = getenv('GTAG_ID') ?: 'G-92RYJE4TV4';

    // Ne charger gtag que si un ID est fourni
    if (empty($measurement_id)) {
        return;
    }

    ?>
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=<?php echo esc_attr($measurement_id); ?>"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());

      gtag('config', '<?php echo esc_js($measurement_id); ?>');
    </script>
    <?php
}
add_action('wp_head', 'add_google_analytics');

// Ajouter le favicon avec la bonne URL selon l'environnement
function add_favicon()
{
    if (is_production()) {
        $favicon_url = site_url('/wp-content/uploads/custom/favicon.png');
        echo '<link rel="shortcut icon" href="' . esc_url($favicon_url) . '" />';
    } else {
        echo '<link rel="shortcut icon" href="/wp-content/uploads/custom/favicon.png" />';
    }
}
add_action('wp_head', 'add_favicon');

// Insérer le logo dans le header avec JavaScript et utiliser la bonne URL selon l'environnement
function add_custom_logo_script()
{
    // Préparer les URLs selon l'environnement
    if (is_production()) {
        $logo_url = site_url('/wp-content/uploads/custom/logo.png');
        $home_url = site_url('/');
    } else {
        $logo_url = '/wp-content/uploads/custom/logo.png';
        $home_url = '/';
    }
    ?>

    <?php
}
add_action('wp_footer', 'add_custom_logo_script');

// Style supplémentaire pour placer le menu à droite du logo
function add_custom_header_css()
{
    ?>
    <style type="text/css">
        .inside-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .site-logo {
            margin-right: auto;
        }

        .main-navigation {
            margin-left: auto;
        }

        @media (max-width: 768px) {
            .inside-header {
                flex-direction: column;
            }
        }
    </style>
    <?php
}
add_action('wp_head', 'add_custom_header_css');

// Si en production, ajouter des filtres pour résoudre les problèmes de contenu mixte HTTP/HTTPS
if (is_production()) {
    function fix_mixed_content($content)
    {
        $domain = parse_url(site_url(), PHP_URL_HOST);
        // Convertir les URLs HTTP en HTTPS
        $content = str_replace('http://' . $domain, 'https://' . $domain, $content);
        return $content;
    }

    // Appliquer aux différents types de contenu
    add_filter('the_content', 'fix_mixed_content', 99);
    add_filter('widget_text_content', 'fix_mixed_content', 99);
    add_filter('wp_get_attachment_url', 'fix_mixed_content', 99);
    add_filter('generate_sidebar_layout', function ($layout) {
        if (is_page() || is_single()) {
            return 'no-sidebar';
        }
        return $layout;
    });

    // Forcer HTTPS dans les URLs d'images
    function force_https_for_images($image, $attachment_id, $size, $icon)
    {
        if (is_array($image) && isset($image[0])) {
            $image[0] = str_replace('http://', 'https://', $image[0]);
        }
        return $image;
    }
    add_filter('wp_get_attachment_image_src', 'force_https_for_images', 10, 4);
}




add_filter('generate_sidebar_layout', function ($layout) {
    if (is_page() || is_single()) {
        return 'no-sidebar';
    }
    return $layout;
});


add_filter('generate_copyright','custom_footer_copyright');
function custom_footer_copyright() {
    $site_copyright = getenv('SITE_COPYRIGHT') ?: get_bloginfo('name');
    return '© ' . date('Y') . ' ' . $site_copyright . '. Tous droits réservés.';
}
// Fonction pour afficher notre footer personnalisé

// Ajoute une fonction pour créer un fichier footer-template.php si nécessaire
// add_action('after_switch_theme', callback: 'create_footer_template');
// add_action('generate_after_header', function () {
//     if (function_exists('pll_the_languages')) {
//         $languages = pll_the_languages([
//             'raw' => true,
//             'hide_if_empty' => 0,
//         ]);

//         if (!empty($languages)) {
//             echo '<form class="lang-switcher-form" method="get">';
//             echo '<select onchange="if(this.value) window.location.href=this.value;">';

//             foreach ($languages as $lang) {
//                 $selected = $lang['current_lang'] ? 'selected' : '';
//                 $name = strtoupper($lang['slug']);
//                 $url = $lang['url'];

//                 echo '<option value="' . esc_url($url) . '" ' . $selected . '>' . esc_html($name) . '</option>';
//             }

//             echo '</select>';
//             echo '</form>';
//         }
//     }
// });
// add_filter('wp_nav_menu_items', 'add_language_switcher_to_menu', 10, 2);


// add_filter('wp_nav_menu_items', 'add_language_switcher_to_menu', 10, 2);
// error_log('Theme location: ' . $args->theme_location);

// add_filter('wp_nav_menu_items', 'add_language_switcher_to_menu', 10, 2);
// function add_language_switcher_to_menu($items, $args)
// {
//     error_log('Theme location: ' . $args->theme_location);

//     if ($args->theme_location === 'primary' && function_exists('pll_the_languages')) {
//         $langs = pll_the_languages([
//             'raw' => 1,
//             'hide_if_empty' => 0,
//         ]);

//         $current_lang = pll_current_language();
//         $switcher = '<select class="lang-switcher-select" onchange="if(this.value) window.location.href=this.value">';
//         foreach ($langs as $lang) {
//             $selected = $lang['slug'] === $current_lang ? ' selected' : '';
//             $switcher .= '<option value="' . esc_url($lang['url']) . '"' . $selected . '>' . esc_html(strtoupper($lang['slug'])) . '</option>';
//         }
//         $switcher .= '</select>';

//         $items .= '<li class="menu-item lang-switcher-item">' . $switcher . '</li>';
//     }

//     return $items;
// }
add_action('generate_menu_bar_items', function() {
    if (function_exists('pll_the_languages')) {
        $langs = pll_the_languages([
            'raw' => 1,
            'hide_if_empty' => 0,
        ]);
        if ($langs) {
            echo '<li class="menu-item lang-switcher-item">';
            echo '<select class="lang-switcher-select" onchange="if(this.value) window.location.href=this.value">';
            foreach ($langs as $lang) {
                $selected = $lang['current_lang'] ? ' selected' : '';
                echo '<option value="' . esc_url($lang['url']) . '"' . $selected . '>' . esc_html(strtoupper($lang['slug'])) . '</option>';
            }
            echo '</select>';
            echo '</li>';
        }
    }
});

// Forcer l'utilisation d'images haute résolution
add_filter('wp_get_attachment_image_attributes', 'force_high_quality_images', 10, 3);
function force_high_quality_images($attr, $attachment, $size) {
    // Pour les images dans la mosaïque, forcer une taille plus grande
    if (is_front_page() || is_home()) {
        // Utiliser 'large' au lieu de 'medium' pour une meilleure qualité
        if ($size === 'medium' || $size === 'thumbnail') {
            $image_src = wp_get_attachment_image_src($attachment->ID, 'large');
            if ($image_src) {
                $attr['src'] = $image_src[0];
                $attr['srcset'] = wp_get_attachment_image_srcset($attachment->ID, 'large');
            }
        }
    }
    return $attr;
}

// ========================================
// FOOTER NETWORK LINKS - Chargement depuis CDN static
// ========================================

// Utilitaire: fetch + cache d'un snippet CDN
function lemeon_fetch_snippet_cdn($name, $ttl = 600) { // TTL 10 min
    $key  = 'lemeon_snip_' . sanitize_key($name);
    $html = get_transient($key);

    if ($html === false) {
        $url = 'https://static.le-meon.com/snippets/' . rawurlencode($name) . '.html';
        $res = wp_remote_get($url, ['timeout' => 5, 'redirection' => 2]);

        if (!is_wp_error($res) && wp_remote_retrieve_response_code($res) === 200) {
            $html = wp_remote_retrieve_body($res);
        } else {
            $html = ''; // fallback silencieux
        }
        set_transient($key, $html, $ttl);
    }
    return $html;
}

// Hook GeneratePress: place le bloc juste après le footer
add_action('generate_after_footer', function () {
    $snippet = lemeon_fetch_snippet_cdn('footer-links', 600);
    if ($snippet) {
        echo '<div class="footer-links-shared" role="complementary">' . $snippet . '</div>';
    }
}, 20);
  /**
   * Auto-generate meta descriptions from meta.seo
   * Maps N8N Claude-generated descriptions to RankMath
   */
  add_action('wp_insert_post', 'auto_generate_rank_math_description', 10, 3);
  function auto_generate_rank_math_description($post_id, $post, $update) {
      // Ne traiter que les posts publiés
      if ($post->post_type !== 'post' || $post->post_status !== 'publish') {
          return;
      }

      // Récupérer la description existante
      $existing_desc = get_post_meta($post_id, 'rank_math_description', true);

      // Si elle existe déjà, ne pas la remplacer
      if (!empty($existing_desc)) {
          return;
      }

      // Récupérer la description depuis meta.seo (envoyée par N8N)
      $seo_description = get_post_meta($post_id, 'seo', true);

      // Si pas de seo, générer à partir du contenu
      if (empty($seo_description) && !empty($post->post_content)) {
          // Extraire les 160 premiers caractères du contenu (sans HTML)
          $seo_description = substr(strip_tags($post->post_content), 0, 160);
          // Ajouter "..." si le contenu était plus long
          if (strlen(strip_tags($post->post_content)) > 160) {
              $seo_description .= '...';
          }
      }

      // Sauvegarder comme rank_math_description
      if (!empty($seo_description)) {
          update_post_meta($post_id, 'rank_math_description', $seo_description);
      }

      // Générer aussi un excerpt si absent
      if (empty($post->post_excerpt) && !empty($seo_description)) {
          wp_update_post(array(
              'ID' => $post_id,
              'post_excerpt' => $seo_description
          ));
      }
  }

// Route de purge pour admins: ?flush_shared_footer=1
add_action('init', function () {
    if (is_user_logged_in() && current_user_can('manage_options') && isset($_GET['flush_shared_footer'])) {
        global $wpdb;
        $wpdb->query("DELETE FROM {$wpdb->options} WHERE option_name LIKE '_transient_lemeon_snip_%' OR option_name LIKE '_transient_timeout_lemeon_snip_%'");
        wp_redirect(remove_query_arg('flush_shared_footer'));
        exit;
    }
});

// ========================================
// SEO: ROBOTS.TXT AMÉLIORÉ
// ========================================
// Ajoute des règles de blocage pour éviter l'indexation de fichiers internes
add_filter('robots_txt', 'custom_robots_txt', 10, 2);
function custom_robots_txt($output, $public) {
    // Ajouter des règles de blocage supplémentaires
    $custom_rules = "
# Block internal WordPress files
Disallow: /wp-content/themes/*/
Disallow: /wp-content/plugins/*/
Disallow: /wp-includes/
Disallow: /wp-admin/
Disallow: /*.php$
Disallow: /*?*
Disallow: /feed/
Disallow: /trackback/
Disallow: /xmlrpc.php

# Block URLs with quotes (malformed)
Disallow: /*\"*
Disallow: /*'*

# Allow important files
Allow: /wp-content/uploads/

# Sitemap
Sitemap: " . home_url('/sitemap_index.xml') . "
";

    return $output . $custom_rules;
}
