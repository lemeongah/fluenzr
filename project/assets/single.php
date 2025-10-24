<?php
/**
 * Single Post Template - GeneratePress Child Theme
 * Affiche un article avec un design épuré et moderne
 */

get_header();
?>

<div class="modern-single-article">
    <article id="post-<?php the_ID(); ?>" <?php post_class( 'single-post-wrapper' ); ?>>

        <!-- Image mise en avant pleine largeur -->
        <?php
        if ( has_post_thumbnail() ) {
            ?>
            <div class="featured-image-full">
                <?php the_post_thumbnail( 'full', array( 'class' => 'responsive-img' ) ); ?>
            </div>
            <?php
        }
        ?>

        <!-- Contenu principal -->
        <div class="article-content-wrapper">
            <!-- En-tête avec titre et métadonnées discrets -->
            <header class="article-header">
                <h1 class="article-title">
                    <?php the_title(); ?>
                </h1>

                <div class="article-meta">
                    <time class="meta-date" datetime="<?php echo esc_attr( get_the_date( 'c' ) ); ?>">
                        <?php echo esc_html( get_the_date( 'd M Y' ) ); ?>
                    </time>
                    <?php
                    $categories = get_the_category();
                    if ( ! empty( $categories ) ) {
                        foreach ( $categories as $category ) {
                            echo '<a href="' . esc_url( get_category_link( $category->term_id ) ) . '" class="meta-category">' . esc_html( $category->name ) . '</a>';
                        }
                    }
                    ?>
                </div>
            </header>

            <!-- Contenu de l'article -->
            <div class="article-body">
                <?php
                the_content(
                    sprintf(
                        wp_kses(
                            __( 'Continue reading<span class="screen-reader-text"> "%s"</span>', 'generatepress' ),
                            array(
                                'span' => array(
                                    'class' => array(),
                                ),
                            )
                        ),
                        wp_kses_post( get_the_title() )
                    )
                );

                wp_link_pages(
                    array(
                        'before' => '<div class="page-links">' . esc_html__( 'Pages:', 'generatepress' ),
                        'after'  => '</div>',
                    )
                );
                ?>
            </div>

            <!-- Tags et partage social -->
            <footer class="article-footer">
                <div class="footer-content">
                    <!-- Tags -->
                    <div class="article-tags">
                        <?php
                        $tags = get_the_tags();
                        if ( ! empty( $tags ) ) {
                            foreach ( $tags as $tag ) {
                                echo '<a href="' . esc_url( get_tag_link( $tag->term_id ) ) . '" class="tag-link">#' . esc_html( $tag->name ) . '</a>';
                            }
                        }
                        ?>
                    </div>

                    <!-- Partage social -->
                    <div class="social-share">
                        <?php
                        $post_url = urlencode( get_permalink() );
                        $post_title = urlencode( get_the_title() );
                        $excerpt = urlencode( wp_strip_all_tags( get_the_excerpt() ) );
                        ?>
                        <span class="share-label">Partager:</span>
                        <a href="https://www.facebook.com/sharer/sharer.php?u=<?php echo $post_url; ?>" class="share-btn facebook" target="_blank" rel="noopener noreferrer" title="Facebook">f</a>
                        <a href="https://x.com/intent/tweet?url=<?php echo $post_url; ?>&text=<?php echo $post_title; ?>" class="share-btn twitter" target="_blank" rel="noopener noreferrer" title="X">𝕏</a>
                        <a href="https://www.linkedin.com/sharing/share-offsite/?url=<?php echo $post_url; ?>" class="share-btn linkedin" target="_blank" rel="noopener noreferrer" title="LinkedIn">in</a>
                        <a href="https://pinterest.com/pin/create/button/?url=<?php echo $post_url; ?>&description=<?php echo $excerpt; ?>" class="share-btn pinterest" target="_blank" rel="noopener noreferrer" title="Pinterest">P</a>
                    </div>
                </div>
            </footer>
        </div>

        <!-- Navigation article précédent/suivant - Pleine largeur -->
        <nav class="post-navigation-full">
            <div class="nav-container">
                <?php
                $prev_post = get_previous_post();
                $next_post = get_next_post();

                if ( $prev_post ) {
                    $prev_url = get_permalink( $prev_post );
                    $prev_title = get_the_title( $prev_post );
                    $prev_excerpt = wp_strip_all_tags( get_the_excerpt( $prev_post ) );
                    $prev_image = get_the_post_thumbnail_url( $prev_post, 'medium' );
                    ?>
                    <div class="nav-prev">
                        <a href="<?php echo esc_url( $prev_url ); ?>" class="nav-card">
                            <?php if ( $prev_image ) { ?>
                                <div class="nav-image">
                                    <img src="<?php echo esc_url( $prev_image ); ?>" alt="<?php echo esc_attr( $prev_title ); ?>">
                                </div>
                            <?php } ?>
                            <div class="nav-info">
                                <span class="nav-label">Article précédent</span>
                                <h3><?php echo esc_html( $prev_title ); ?></h3>
                                <p><?php echo wp_trim_words( $prev_excerpt, 12 ); ?></p>
                            </div>
                        </a>
                    </div>
                    <?php
                }

                if ( $next_post ) {
                    $next_url = get_permalink( $next_post );
                    $next_title = get_the_title( $next_post );
                    $next_excerpt = wp_strip_all_tags( get_the_excerpt( $next_post ) );
                    $next_image = get_the_post_thumbnail_url( $next_post, 'medium' );
                    ?>
                    <div class="nav-next">
                        <a href="<?php echo esc_url( $next_url ); ?>" class="nav-card">
                            <?php if ( $next_image ) { ?>
                                <div class="nav-image">
                                    <img src="<?php echo esc_url( $next_image ); ?>" alt="<?php echo esc_attr( $next_title ); ?>">
                                </div>
                            <?php } ?>
                            <div class="nav-info">
                                <span class="nav-label">Article suivant</span>
                                <h3><?php echo esc_html( $next_title ); ?></h3>
                                <p><?php echo wp_trim_words( $next_excerpt, 12 ); ?></p>
                            </div>
                        </a>
                    </div>
                    <?php
                }
                ?>
            </div>
        </nav>

    </article>

    <?php
    if ( comments_open() || get_comments_number() ) {
        comments_template();
    }
    ?>
</div>

<style>
/* ========================================
   Modern Single Article Design
   ======================================== */

.modern-single-article {
    width: 100%;
    background: #ffffff;
}

.single-post-wrapper {
    width: 100%;
}

/* Image mise en avant pleine largeur */
.featured-image-full {
    width: 100%;
    height: 400px;
    margin: 0;
    overflow: hidden;
}

.featured-image-full .responsive-img {
    width: 100%;
    height: 100%;
    display: block;
    object-fit: cover;
}

/* Contenu principal */
.article-content-wrapper {
    max-width: 800px;
    margin: 0 auto;
    padding: 3rem 2rem;
}

/* En-tête article */
.article-header {
    margin-bottom: 2rem;
}

.article-title {
    font-size: 2.5rem;
    line-height: 1.2;
    margin: 0 0 1rem 0;
    color: #1a1a1a;
    font-weight: 700;
}

.article-meta {
    display: flex;
    gap: 2rem;
    align-items: center;
    font-size: 0.95rem;
    color: #888;
}

.meta-date,
.meta-category {
    color: #888;
    text-decoration: none;
    transition: color 0.3s ease;
}

.meta-category:hover {
    color: #667eea;
}

/* Contenu de l'article */
.article-body {
    font-size: 1.1rem;
    line-height: 1.8;
    color: #333;
    margin: 2rem 0;
}

.article-body p {
    margin-bottom: 1.5rem;
}

.article-body h2,
.article-body h3 {
    margin-top: 2.5rem;
    margin-bottom: 1rem;
    color: #1a1a1a;
    font-weight: 700;
}

.article-body h2 {
    font-size: 1.8rem;
}

.article-body h3 {
    font-size: 1.4rem;
}

.article-body a {
    color: #667eea;
    text-decoration: none;
    border-bottom: 2px solid #667eea;
    transition: color 0.3s ease;
}

.article-body a:hover {
    color: #764ba2;
    border-bottom-color: #764ba2;
}

.article-body ul,
.article-body ol {
    margin: 1.5rem 0 1.5rem 2rem;
}

.article-body li {
    margin-bottom: 0.8rem;
}

.article-body blockquote {
    padding: 1.5rem;
    margin: 2rem 0;
    border-left: 4px solid #667eea;
    background: #f8f9ff;
    border-radius: 0 8px 8px 0;
    font-style: italic;
    color: #555;
}

/* Footer - Tags et partage */
.article-footer {
    padding-top: 2rem;
    border-top: 1px solid #eee;
    margin-top: 3rem;
}

.footer-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 2rem;
    flex-wrap: wrap;
}

.article-tags {
    display: flex;
    gap: 0.8rem;
    flex-wrap: wrap;
}

.tag-link {
    padding: 0.5rem 1rem;
    background: #f0f0f0;
    color: #667eea;
    border-radius: 20px;
    text-decoration: none;
    font-size: 0.9rem;
    transition: all 0.3s ease;
}

.tag-link:hover {
    background: #667eea;
    color: white;
}

/* Partage social */
.social-share {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.share-label {
    font-size: 0.9rem;
    color: #888;
    font-weight: 500;
}

.share-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: #e8eaf6;
    color: #667eea;
    text-decoration: none;
    font-weight: bold;
    transition: all 0.3s ease;
}

.share-btn:hover {
    background: #667eea;
    color: white;
    transform: scale(1.1);
}

.share-btn.facebook:hover { background: #1877f2; }
.share-btn.twitter:hover { background: #000; }
.share-btn.linkedin:hover { background: #0a66c2; }
.share-btn.pinterest:hover { background: #e60023; }

/* ========================================
   Navigation article précédent/suivant
   ======================================== */

.post-navigation-full {
    width: 100%;
    background: #f9f9f9;
    padding: 3rem 2rem;
    margin-top: 3rem;
    border-top: 1px solid #eee;
}

.nav-container {
    max-width: 1400px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 3rem;
}

.nav-prev,
.nav-next {
    width: 100%;
}

.nav-card {
    display: flex;
    gap: 1.5rem;
    padding: 1.5rem;
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 12px;
    text-decoration: none;
    color: inherit;
    transition: all 0.3s ease;
    height: 100%;
}

.nav-card:hover {
    border-color: #667eea;
    box-shadow: 0 8px 20px rgba(102, 126, 234, 0.15);
    transform: translateY(-3px);
}

.nav-image {
    flex-shrink: 0;
    width: 150px;
    height: 150px;
    border-radius: 8px;
    overflow: hidden;
    background: #f0f0f0;
}

.nav-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.nav-info {
    flex: 1;
    display: flex;
    flex-direction: column;
}

.nav-label {
    font-size: 0.85rem;
    color: #999;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    font-weight: 600;
    margin-bottom: 0.5rem;
}

.nav-info h3 {
    font-size: 1.2rem;
    font-weight: 700;
    margin: 0 0 0.8rem 0;
    color: #1a1a1a;
    line-height: 1.3;
}

.nav-info p {
    margin: 0;
    font-size: 0.95rem;
    color: #666;
    line-height: 1.5;
}

/* Responsive */
@media (max-width: 900px) {
    .article-content-wrapper {
        padding: 2rem 1.5rem;
    }

    .article-title {
        font-size: 2rem;
    }

    .article-meta {
        gap: 1.5rem;
        font-size: 0.9rem;
    }

    .nav-container {
        gap: 2rem;
    }
}

@media (max-width: 768px) {
    .featured-image-full {
        height: 250px;
    }

    .article-content-wrapper {
        padding: 1.5rem 1rem;
        max-width: 100%;
    }

    .article-title {
        font-size: 1.6rem;
    }

    .article-body {
        font-size: 1rem;
    }

    .footer-content {
        flex-direction: column;
        align-items: flex-start;
    }

    .post-navigation-full {
        padding: 2rem 1rem;
    }

    .nav-container {
        grid-template-columns: 1fr;
        gap: 1.5rem;
    }

    .nav-card {
        flex-direction: column;
        padding: 1rem;
    }

    .nav-image {
        width: 100%;
        height: 200px;
    }

    .article-meta {
        flex-direction: column;
        align-items: flex-start;
        gap: 0.5rem;
    }
}

/* Dark mode */
@media (prefers-color-scheme: dark) {
    .modern-single-article {
        background: #1e1e1e;
        color: #e8e8e8;
    }

    .article-title,
    .nav-info h3 {
        color: #fff;
    }

    .article-body,
    .article-meta,
    .meta-date,
    .meta-category {
        color: #ccc;
    }

    .article-footer {
        border-top-color: #333;
    }

    .tag-link {
        background: #2a2a2a;
        color: #8ab4f8;
    }

    .tag-link:hover {
        background: #667eea;
    }

    .nav-card {
        background: #262626;
        border-color: #404040;
    }

    .nav-info p {
        color: #aaa;
    }

    .post-navigation-full {
        background: #1a1a1a;
        border-top-color: #333;
    }
}
</style>

<?php
get_footer();
