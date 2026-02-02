#!/usr/bin/env bash

# Blog Engine for bash.d Platform
# Markdown-based blog with workflow, publishing, and management

# Source core functions
source "$(dirname "${BASH_SOURCE[0]}")/../src/core.sh"

# Blog configuration
readonly BLOG_DIR="$HOME/.bash.d/data/content/blog"
readonly BLOG_DRAFTS_DIR="$BLOG_DIR/drafts"
readonly BLOG_PUBLISHED_DIR="$BLOG_DIR/published"
readonly BLOG_TEMPLATES_DIR="$HOME/.bash.d/templates/blog"
readonly BLOG_CONFIG_FILE="$HOME/.bash.d/config/blog.yaml"

# Initialize blog engine
init_blog() {
    log "INFO" "Initializing blog engine..."
    
    # Create directories
    ensure_dir "$BLOG_DIR"
    ensure_dir "$BLOG_DRAFTS_DIR"
    ensure_dir "$BLOG_PUBLISHED_DIR"
    ensure_dir "$BLOG_TEMPLATES_DIR"
    
    # Create default configuration
    if [[ ! -f "$BLOG_CONFIG_FILE" ]]; then
        create_default_blog_config
    fi
    
    success "Blog engine initialized"
}

# Create default blog configuration
create_default_blog_config() {
    cat > "$BLOG_CONFIG_FILE" << EOF
# Blog Configuration
site:
  title: "cbwinslow's Blog"
  description: "Thoughts on technology, data, and development"
  author: "cbwinslow"
  email: "blaine.winslow@gmail.com"
  domain: "cloudcurio.cc"
  
theme:
  name: "default"
  syntax_highlighting: true
  dark_mode: false
  
features:
  comments: true
  rss: true
  search: true
  analytics: true
  
publishing:
  auto_deploy: true
  ping_services: true
  sitemap: true
  
seo:
  meta_description: true
  open_graph: true
  twitter_card: true
EOF
}

# Create new blog post
create_post() {
    local title="$1"
    local slug="${2:-$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/-$//')}"
    local tags="${3:-}"
    local draft="${4:-true}"
    
    if [[ -z "$title" ]]; then
        error "Title is required"
        return 1
    fi
    
    log "INFO" "Creating blog post: $title"
    
    # Create front matter
    local front_matter=$(create_front_matter "$title" "$slug" "$tags")
    
    # Create content
    local content_dir="$BLOG_DRAFTS_DIR"
    if [[ "$draft" == "false" ]]; then
        content_dir="$BLOG_PUBLISHED_DIR"
    fi
    
    local post_file="$content_dir/${slug}.md"
    
    # Create the post file
    cat > "$post_file" << EOF
$front_matter

# $(echo "$title" | tr '[:lower:]' '[:upper:]')

Welcome to this blog post about "$title". This is a placeholder content that you should replace with your actual writing.

## Key Points

- Point 1 about the topic
- Point 2 with supporting details
- Point 3 with examples or code

## Code Example

\`\`\`bash
# Example code related to $title
echo "Hello, World!"
\`\`\`

## Conclusion

This is just the beginning of what will become a comprehensive blog post about "$title". Stay tuned for more updates!

---

*Tags: $(echo "${tags:-technology,bash,d development}" | sed 's/,/, /g')*
EOF
    
    success "Blog post created: $post_file"
    
    # Open in editor if EDITOR is set
    if [[ -n "${EDITOR:-}" ]]; then
        log "INFO" "Opening in editor: $EDITOR"
        "$EDITOR" "$post_file"
    fi
}

# Create front matter for blog post
create_front_matter() {
    local title="$1"
    local slug="$2"
    local tags="$3"
    local date=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat << EOF
---
title: "$title"
slug: "$slug"
date: "$date"
author: "cbwinslow"
email: "blaine.winslow@gmail.com"
tags: [$(echo "$tags" | sed 's/,/, /g' | sed 's/^/"/; s/$/"/')]
draft: false
description: "Blog post about $title"
---
EOF
}

# List blog posts
list_posts() {
    local status="${1:-all}"
    local limit="${2:-10}"
    
    log "INFO" "Listing blog posts (status: $status, limit: $limit)"
    
    case "$status" in
        "draft")
            find "$BLOG_DRAFTS_DIR" -name "*.md" -printf "%f\t%T\t%p\n" | head -n "$limit"
            ;;
        "published")
            find "$BLOG_PUBLISHED_DIR" -name "*.md" -printf "%f\t%T\t%p\n" | head -n "$limit"
            ;;
        "all"|*)
            echo "Drafts:"
            find "$BLOG_DRAFTS_DIR" -name "*.md" -printf "  %f\t%T\t%p\n" | head -n "$((limit/2))"
            echo ""
            echo "Published:"
            find "$BLOG_PUBLISHED_DIR" -name "*.md" -printf "  %f\t%T\t%p\n" | head -n "$((limit/2))"
            ;;
    esac
}

# Publish blog post
publish_post() {
    local slug="$1"
    
    if [[ -z "$slug" ]]; then
        error "Slug is required"
        return 1
    fi
    
    local draft_file="$BLOG_DRAFTS_DIR/${slug}.md"
    local published_file="$BLOG_PUBLISHED_DIR/${slug}.md"
    
    if [[ ! -f "$draft_file" ]]; then
        error "Draft post not found: $slug"
        return 1
    fi
    
    log "INFO" "Publishing post: $slug"
    
    # Move from drafts to published
    mv "$draft_file" "$published_file"
    
    # Update front matter to remove draft status
    sed -i 's/draft: true/draft: false/' "$published_file"
    
    # Trigger deployment if configured
    if grep -q "auto_deploy: true" "$BLOG_CONFIG_FILE"; then
        log "INFO" "Triggering auto-deployment..."
        deploy_blog_to_platform
    fi
    
    success "Post published: $slug"
}

# Deploy blog to platform
deploy_blog_to_platform() {
    log "INFO" "Deploying blog to Cloudflare platform..."
    
    # This would integrate with the platform deployment
    # For now, just show what would happen
    echo "Would deploy to: cloudcurio.cc/blog"
    echo "Posts to deploy:"
    find "$BLOG_PUBLISHED_DIR" -name "*.md" -printf "  %p\n"
    
    # Generate RSS feed
    generate_rss_feed
    
    # Generate sitemap
    generate_sitemap
}

# Generate RSS feed
generate_rss_feed() {
    local rss_file="$BLOG_PUBLISHED_DIR/rss.xml"
    
    log "INFO" "Generating RSS feed..."
    
    cat > "$rss_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>cbwinslow's Blog</title>
    <description>Thoughts on technology, data, and development</description>
    <link>https://cloudcurio.cc/blog</link>
    <language>en-us</language>
    <pubDate>$(date '+%a, %d %b %Y %H:%M:%S %z')</pubDate>
    <lastBuildDate>$(date '+%a, %d %b %Y %H:%M:%S %z')</lastBuildDate>
    
$(find "$BLOG_PUBLISHED_DIR" -name "*.md" -exec grep -l "date: " {} \; | head -20 | while read -r file; do
    title=$(grep "^title: " "$file" | sed 's/title: "//; s/"//g')
    slug=$(basename "$file" .md)
    pub_date=$(grep "^date: " "$file" | sed 's/date: "//; s/"//g')
    link="https://cloudcurio.cc/blog/$slug"
    
    cat << ITEM_EOF
    <item>
      <title>$title</title>
      <link>$link</link>
      <pubDate>$pub_date</pubDate>
      <guid>$link</guid>
    </item>
ITEM_EOF
done)
    
  </channel>
</rss>
EOF
    
    success "RSS feed generated: $rss_file"
}

# Generate sitemap
generate_sitemap() {
    local sitemap_file="$BLOG_PUBLISHED_DIR/sitemap.xml"
    
    log "INFO" "Generating sitemap..."
    
    cat > "$sitemap_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  
$(find "$BLOG_PUBLISHED_DIR" -name "*.md" -exec basename {} .md \; | while read -r slug; do
    cat << URL_EOF
  <url>
    <loc>https://cloudcurio.cc/blog/$slug</loc>
    <lastmod>$(date '+%Y-%m-%d')</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
URL_EOF
done)
  
</urlset>
EOF
    
    success "Sitemap generated: $sitemap_file"
}

# Search blog posts
search_posts() {
    local query="$1"
    local limit="${2:-10}"
    
    if [[ -z "$query" ]]; then
        error "Search query is required"
        return 1
    fi
    
    log "INFO" "Searching blog posts for: $query"
    
    # Simple search through markdown files
    find "$BLOG_PUBLISHED_DIR" -name "*.md" -exec grep -l -i "$query" {} \; | head -n "$limit" | while read -r file; do
        local title=$(grep "^title: " "$file" | sed 's/title: "//; s/"//g')
        local slug=$(basename "$file" .md)
        local excerpt=$(grep -A 5 -m 1 "^#" "$file" | head -n 1 | sed 's/^#//')
        
        echo "📝 $title"
        echo "   📍 cloudcurio.cc/blog/$slug"
        echo "   📄 $excerpt"
        echo ""
    done
}

# Blog statistics
blog_stats() {
    log "INFO" "Blog statistics:"
    
    local draft_count=$(find "$BLOG_DRAFTS_DIR" -name "*.md" | wc -l)
    local published_count=$(find "$BLOG_PUBLISHED_DIR" -name "*.md" | wc -l)
    local total_words=0
    
    # Count words in published posts
    find "$BLOG_PUBLISHED_DIR" -name "*.md" -exec wc -w {} \; | awk '{sum += $1} END {print sum}')
    
    echo "  Draft posts: $draft_count"
    echo "  Published posts: $published_count"
    echo "  Total words: $total_words"
    echo "  Average words per post: $((total_words / (published_count > 0 ? published_count : 1)))"
}

# Export blog functions
export -f init_blog
export -f create_post
export -f create_front_matter
export -f list_posts
export -f publish_post
export -f deploy_blog_to_platform
export -f generate_rss_feed
export -f generate_sitemap
export -f search_posts
export -f blog_stats