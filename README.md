# philiprehberger-timeout_kit

[![Tests](https://github.com/philiprehberger/rb-timeout-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-timeout-kit/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-timeout_kit.svg)](https://rubygems.org/gems/philiprehberger-timeout_kit)
[![License](https://img.shields.io/github/license/philiprehberger/rb-timeout-kit)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Safe timeout patterns without Thread.raise

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-timeout_kit"
```

Or install directly:

```bash
gem install philiprehberger-timeout_kit
```

## Usage

```ruby
require "philiprehberger/timeout_kit"

Philiprehberger::TimeoutKit.deadline(5) do |d|
  loop do
    d.check!  # raises DeadlineExceeded if time is up
    process_next_item
  end
end
```

### Remaining Time

```ruby
Philiprehberger::TimeoutKit.deadline(10) do |d|
  while d.remaining > 1
    do_work
    d.check!
  end
  puts "Only #{d.remaining}s left, wrapping up"
end
```

### Nested Deadlines

```ruby
Philiprehberger::TimeoutKit.deadline(30) do |outer|
  # Inner deadline is tighter, so it takes precedence
  Philiprehberger::TimeoutKit.deadline(5) do |inner|
    inner.check!
    puts inner.remaining  # <= 5
  end

  # After inner block, outer deadline is restored
  outer.check!
  puts outer.remaining  # <= 30
end
```

### Cooperative Timeout

```ruby
Philiprehberger::TimeoutKit.cooperative(5) do |t|
  items.each do |item|
    t.check!
    process(item)
  end
end
```

### Current Deadline

```ruby
Philiprehberger::TimeoutKit.deadline(10) do |_d|
  current = Philiprehberger::TimeoutKit.current_deadline
  puts current.remaining
end
```

## API

| Method | Description |
|--------|-------------|
| `.deadline(seconds) { \|d\| }` | Execute a block with a cooperative deadline |
| `.cooperative(seconds) { \|t\| }` | Execute a block with a simple cooperative timeout |
| `.current_deadline` | Return the current active deadline or nil |
| `Deadline#check!` | Raise `DeadlineExceeded` if the deadline has passed |
| `Deadline#remaining` | Seconds remaining until the deadline (0.0 if expired) |
| `Deadline#expired?` | Whether the deadline has passed |
| `DeadlineExceeded` | Raised when a deadline or timeout expires |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
