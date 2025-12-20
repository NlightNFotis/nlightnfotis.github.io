---
layout: default
title: Archives
permalink: /archives/
---

<section class="home-section">
  <h2 class="section-title title-posts">ARCHIVES</h2>
  
  <div class="post-list-compact">
    {% for post in site.posts %}
      <div class="post-row-wrapper">
        <div class="post-row">
          <span class="post-date">{{ post.date | date: "%B %-d, %Y" }}</span>
          <a class="post-link" href="{{ post.url | relative_url }}">{{ post.title }}</a>
        </div>

        {% if post.tags.size > 0 %}
        <div class="post-tags">
          {% for tag in post.tags %}
            <a class="tag" href="/tags/{{ tag | slugify }}/">#{{ tag }}</a>
          {% endfor %}
        </div>
        {% endif %}
      </div>
    {% endfor %}
  </div>

  <div style="margin-top: 60px; border-top: 1px solid #eee; padding-top: 20px;">
    <a href="/">← Back to Home</a>
  </div>
</section>
