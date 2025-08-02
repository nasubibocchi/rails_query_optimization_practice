# ユーザー作成
users = [
  User.create!(name: "田中太郎", email: "tanaka@example.com", status: "active"),
  User.create!(name: "佐藤花子", email: "sato@example.com", status: "active"),
  User.create!(name: "山田次郎", email: "yamada@example.com", status: "inactive")
]

# カテゴリ作成
categories = [
  Category.create!(name: "技術", description: "プログラミング関連"),
  Category.create!(name: "日常", description: "日常の出来事"),
  Category.create!(name: "旅行", description: "旅行記録")
]

# タグ作成
tags = [
  Tag.create!(name: "Ruby"),
  Tag.create!(name: "Rails"),
  Tag.create!(name: "JavaScript"),
  Tag.create!(name: "趣味"),
  Tag.create!(name: "仕事")
]

# 記事作成
posts = [
  Post.create!(title: "Railsの基礎", content: "Railsについて学びました", status: "published", user: users[0], category: categories[0], published_at: 1.week.ago),
  Post.create!(title: "今日の日記", content: "今日は良い天気でした", status: "published", user: users[1], category: categories[1], published_at: 3.days.ago),
  Post.create!(title: "下書き記事", content: "まだ書きかけです", status: "draft", user: users[0], category: categories[0]),
  Post.create!(title: "非アクティブユーザーの記事", content: "このユーザーは非アクティブです", status: "published", user: users[2], category: categories[2], published_at: 2.days.ago)
]

# 記事とタグの関連付け
PostTag.create!(post: posts[0], tag: tags[0]) # Ruby
PostTag.create!(post: posts[0], tag: tags[1]) # Rails
PostTag.create!(post: posts[1], tag: tags[3]) # 趣味
PostTag.create!(post: posts[3], tag: tags[4]) # 仕事

# コメント作成
Comment.create!(content: "とても参考になりました！", status: "approved", user: users[1], post: posts[0])
Comment.create!(content: "質問があります", status: "pending", user: users[0], post: posts[1])
Comment.create!(content: "いいですね", status: "approved", user: users[2], post: posts[0])
