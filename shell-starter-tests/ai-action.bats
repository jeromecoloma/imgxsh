#!/usr/bin/env bats
#
# Tests for ai-action demo script

# Load test helpers
load test_helper
load bats-support/load
load bats-assert/load

setup() {
	# Create a temporary test file for file-based tests
	export TEST_FILE
	TEST_FILE=$(mktemp)
	echo "This is test content for AI analysis and processing." > "$TEST_FILE"
}

teardown() {
	# Clean up temporary test file
	if [[ -n "$TEST_FILE" && -f "$TEST_FILE" ]]; then
		rm "$TEST_FILE"
	fi
}

# Help and version tests
@test "ai-action: help flag" {
	run_script "ai-action" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "AI integration example demonstrating various AI operations"
	assert_output --partial "COMMANDS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "EXAMPLES:"
	assert_output --partial "ENVIRONMENT:"
}

@test "ai-action: short help flag" {
	run_script "ai-action" -h
	assert_success
	assert_output --partial "Usage:"
}

@test "ai-action: version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "ai-action" --version
	assert_success
	assert_output --partial "ai-action"
	assert_output --partial "$expected_version"
}

@test "ai-action: short version flag" {
	expected_version=$(cat "${PROJECT_ROOT}/VERSION" | tr -d '\n')
	run_script "ai-action" -v
	assert_success
	assert_output --partial "ai-action"
	assert_output --partial "$expected_version"
}

# No command error
@test "ai-action: no command specified shows error and help" {
	run_script "ai-action"
	assert_failure
	assert_output --partial "No command specified"
	assert_output --partial "AI integration example demonstrating various AI operations"
}

@test "ai-action: unknown command shows error" {
	run_script "ai-action" "unknown-command"
	assert_failure
	assert_output --partial "Unknown command: unknown-command"
	assert_output --partial "Use --help to see available commands"
}

# Global options tests
@test "ai-action: verbose flag" {
	run_script "ai-action" --verbose "explain" "test query"
	assert_success
	assert_output --partial "AI Explanation"
}

@test "ai-action: model option" {
	run_script "ai-action" --model "gpt-4" "explain" "test query"
	assert_success
	assert_output --partial "AI Explanation"
}

@test "ai-action: api-key option" {
	run_script "ai-action" --api-key "test-key" "explain" "test query"
	assert_success
	assert_output --partial "AI Explanation"
}

@test "ai-action: max-tokens option" {
	run_script "ai-action" --max-tokens "500" "explain" "test query"
	assert_success
	assert_output --partial "AI Explanation"
}

@test "ai-action: temperature option" {
	run_script "ai-action" --temperature "0.9" "explain" "test query"
	assert_success
	assert_output --partial "AI Explanation"
}

@test "ai-action: unknown global option" {
	run_script "ai-action" --unknown-global
	assert_failure
	assert_output --partial "Unknown global option: --unknown-global"
}

# Analyze command tests
@test "ai-action: analyze command help" {
	run_script "ai-action" "analyze" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Analyze text content or files using AI"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--file"
	assert_output --partial "--text"
	assert_output --partial "--type"
	assert_output --partial "--format"
}

@test "ai-action: analyze with text input" {
	run_script "ai-action" "analyze" --text "Sample text for analysis"
	assert_success
	assert_output --partial "AI Analysis Results"
	assert_output --partial "Summary:"
	assert_output --partial "Quality:"
	assert_output --partial "Analysis completed successfully"
}

@test "ai-action: analyze with file input" {
	run_script "ai-action" "analyze" --file "$TEST_FILE"
	assert_success
	assert_output --partial "Reading file:"
	assert_output --partial "AI Analysis Results"
	assert_output --partial "Analysis completed successfully"
}

@test "ai-action: analyze with sentiment type" {
	run_script "ai-action" "analyze" --text "I love this!" --type "sentiment"
	assert_success
	assert_output --partial "Sentiment:"
	assert_output --partial "Tone:"
	assert_output --partial "Emotion:"
}

@test "ai-action: analyze with keywords type" {
	run_script "ai-action" "analyze" --text "Technology and programming" --type "keywords"
	assert_success
	assert_output --partial "Key Topics:"
	assert_output --partial "Entities:"
	assert_output --partial "Concepts:"
}

@test "ai-action: analyze with structure type" {
	run_script "ai-action" "analyze" --text "Test content" --type "structure"
	assert_success
	assert_output --partial "Structure:"
	assert_output --partial "Readability:"
	assert_output --partial "Length:"
}

@test "ai-action: analyze with JSON format" {
	run_script "ai-action" "analyze" --text "Test" --format "json"
	assert_success
	assert_output --partial "JSON Output:"
	assert_output --partial "{"
	assert_output --partial "\"analysis_type\":"
	assert_output --partial "\"content_length\":"
	assert_output --partial "}"
}

@test "ai-action: analyze without input fails" {
	run_script "ai-action" "analyze"
	assert_failure
	assert_output --partial "Either --file or --text must be specified"
}

@test "ai-action: analyze with non-existent file fails" {
	run_script "ai-action" "analyze" --file "/non/existent/file.txt"
	assert_failure
	assert_output --partial "File not found:"
}

# Generate command tests
@test "ai-action: generate command help" {
	run_script "ai-action" "generate" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Generate content using AI"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--prompt"
	assert_output --partial "--output"
	assert_output --partial "--type"
	assert_output --partial "--creativity"
}

@test "ai-action: generate with text prompt" {
	run_script "ai-action" "generate" --prompt "Write a simple function"
	assert_success
	assert_output --partial "Generated Content:"
	assert_output --partial "Content generation completed successfully"
}

@test "ai-action: generate with positional prompt" {
	run_script "ai-action" "generate" "Write a simple function"
	assert_success
	assert_output --partial "Generated Content:"
}

@test "ai-action: generate code type" {
	run_script "ai-action" "generate" --type "code" --prompt "Sort function"
	assert_success
	assert_output --partial "#!/bin/bash"
	assert_output --partial "sort_array()"
}

@test "ai-action: generate email type" {
	run_script "ai-action" "generate" --type "email" --prompt "Follow-up email"
	assert_success
	assert_output --partial "Subject:"
	assert_output --partial "Dear"
	assert_output --partial "Best regards"
}

@test "ai-action: generate markdown type" {
	run_script "ai-action" "generate" --type "markdown" --prompt "Documentation"
	assert_success
	assert_output --partial "# Generated Content"
	assert_output --partial "## Overview"
	assert_output --partial "## Key Points"
}

@test "ai-action: generate story type" {
	run_script "ai-action" "generate" --type "story" --prompt "AI story"
	assert_success
	assert_output --partial "The Last Algorithm"
	assert_output --partial "Sarah discovered"
}

@test "ai-action: generate with output file" {
	local output_file
	output_file=$(mktemp)

	run_script "ai-action" "generate" --prompt "Test content" --output "$output_file"
	assert_success
	assert_output --partial "Content saved to:"
	assert [ -f "$output_file" ]

	# Clean up
	rm "$output_file"
}

@test "ai-action: generate without prompt fails" {
	run_script "ai-action" "generate"
	assert_failure
	assert_output --partial "Prompt is required for content generation"
}

# Translate command tests
@test "ai-action: translate command help" {
	run_script "ai-action" "translate" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Translate text between languages"
	assert_output --partial "ARGUMENTS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--to"
	assert_output --partial "--from"
	assert_output --partial "SUPPORTED LANGUAGES:"
}

@test "ai-action: translate to Spanish" {
	run_script "ai-action" "translate" --to "spanish" "Hello world"
	assert_success
	assert_output --partial "Translation Results"
	assert_output --partial "Original"
	assert_output --partial "Translation"
	assert_output --partial "Hola mundo"
}

@test "ai-action: translate to French" {
	run_script "ai-action" "translate" --to "french" "Hello world"
	assert_success
	assert_output --partial "Bonjour le monde"
}

@test "ai-action: translate with source language" {
	run_script "ai-action" "translate" --from "english" --to "german" "Hello world"
	assert_success
	assert_output --partial "Hallo Welt"
}

@test "ai-action: translate with output file" {
	local output_file
	output_file=$(mktemp)

	run_script "ai-action" "translate" --to "spanish" --output "$output_file" "Hello"
	assert_success
	assert_output --partial "Translation saved to:"
	assert [ -f "$output_file" ]

	# Clean up
	rm "$output_file"
}

@test "ai-action: translate without text fails" {
	run_script "ai-action" "translate" --to "spanish"
	assert_failure
	assert_output --partial "Text to translate is required"
}

@test "ai-action: translate without target language fails" {
	run_script "ai-action" "translate" "Hello world"
	assert_failure
	assert_output --partial "Target language (--to) is required"
}

# Summarize command tests
@test "ai-action: summarize command help" {
	run_script "ai-action" "summarize" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Create summaries of text or documents"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--file"
	assert_output --partial "--text"
	assert_output --partial "--length"
	assert_output --partial "--style"
}

@test "ai-action: summarize with text input" {
	run_script "ai-action" "summarize" --text "Long text that needs summarization for testing purposes"
	assert_success
	assert_output --partial "AI-Generated Summary"
	assert_output --partial "Original length:"
	assert_output --partial "Summary length:"
	assert_output --partial "Compression ratio:"
}

@test "ai-action: summarize with file input" {
	run_script "ai-action" "summarize" --file "$TEST_FILE"
	assert_success
	assert_output --partial "Reading file:"
	assert_output --partial "AI-Generated Summary"
}

@test "ai-action: summarize with bullet style" {
	run_script "ai-action" "summarize" --text "Test content" --style "bullet"
	assert_success
	assert_output --partial "•"
}

@test "ai-action: summarize with paragraph style" {
	run_script "ai-action" "summarize" --text "Test content" --style "paragraph"
	assert_success
	assert_output --partial "This content focuses on"
}

@test "ai-action: summarize with outline style" {
	run_script "ai-action" "summarize" --text "Test content" --style "outline"
	assert_success
	assert_output --partial "I."
	assert_output --partial "A."
	assert_output --partial "B."
}

@test "ai-action: summarize with custom length" {
	run_script "ai-action" "summarize" --text "Test content" --length "short"
	assert_success
	assert_output --partial "AI-Generated Summary"
}

@test "ai-action: summarize without input fails" {
	run_script "ai-action" "summarize"
	assert_failure
	assert_output --partial "Either --file or --text must be specified"
}

# Chat command tests
@test "ai-action: chat command help" {
	run_script "ai-action" "chat" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Start an interactive chat session"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--session"
	assert_output --partial "--system"
	assert_output --partial "COMMANDS DURING CHAT:"
}

@test "ai-action: chat with quit command" {
	run bash -c "echo '/quit' | '${PROJECT_ROOT}/demo/ai-action' chat"
	assert_success
	assert_output --partial "AI Chat Session"
	assert_output --partial "Type your messages and press Enter"
	assert_output --partial "Chat session ended"
}

@test "ai-action: chat with help command" {
	run bash -c "printf '/help\n/quit\n' | '${PROJECT_ROOT}/demo/ai-action' chat"
	assert_success
	assert_output --partial "Chat Commands:"
	assert_output --partial "/clear"
	assert_output --partial "/save"
	assert_output --partial "/quit"
}

@test "ai-action: chat with clear command" {
	run bash -c "printf '/clear\n/quit\n' | '${PROJECT_ROOT}/demo/ai-action' chat"
	assert_success
	assert_output --partial "Chat history cleared"
}

@test "ai-action: chat with save command" {
	run bash -c "printf '/save test-session.txt\n/quit\n' | '${PROJECT_ROOT}/demo/ai-action' chat"
	assert_success
	assert_output --partial "Session saved to:"

	# Clean up
	rm -f test-session.txt chat-session-*.txt
}

@test "ai-action: chat with simple interaction" {
	run bash -c "printf 'hello\n/quit\n' | '${PROJECT_ROOT}/demo/ai-action' chat"
	assert_success
	assert_output --partial "You: hello"
	assert_output --partial "AI:"
	assert_output --partial "Hello! How can I help you today?"
}

# Code-review command tests
@test "ai-action: code-review command help" {
	run_script "ai-action" "code-review" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Review code files for best practices"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--file"
	assert_output --partial "--type"
	assert_output --partial "--severity"
}

@test "ai-action: code-review with file" {
	run_script "ai-action" "code-review" --file "$TEST_FILE"
	assert_success
	assert_output --partial "AI Code Review Results"
	assert_output --partial "File:"
	assert_output --partial "Issues Found:"
	assert_output --partial "Summary:"
	assert_output --partial "Code review completed successfully"
}

@test "ai-action: code-review with security type" {
	run_script "ai-action" "code-review" --file "$TEST_FILE" --type "security"
	assert_success
	assert_output --partial "CRITICAL:"
	assert_output --partial "vulnerability"
}

@test "ai-action: code-review with performance type" {
	run_script "ai-action" "code-review" --file "$TEST_FILE" --type "performance"
	assert_success
	assert_output --partial "Inefficient"
	assert_output --partial "performance"
}

@test "ai-action: code-review with style type" {
	run_script "ai-action" "code-review" --file "$TEST_FILE" --type "style"
	assert_success
	assert_output --partial "variable naming"
	assert_output --partial "documentation"
}

@test "ai-action: code-review with output file" {
	local output_file
	output_file=$(mktemp)

	run_script "ai-action" "code-review" --file "$TEST_FILE" --output "$output_file"
	assert_success
	assert_output --partial "Review saved to:"
	assert [ -f "$output_file" ]

	# Clean up
	rm "$output_file"
}

@test "ai-action: code-review without file fails" {
	run_script "ai-action" "code-review"
	assert_failure
	assert_output --partial "Code file is required for review"
}

@test "ai-action: code-review with non-existent file fails" {
	run_script "ai-action" "code-review" --file "/non/existent/file.txt"
	assert_failure
	assert_output --partial "File not found:"
}

# Explain command tests
@test "ai-action: explain command help" {
	run_script "ai-action" "explain" --help
	assert_success
	assert_output --partial "Usage:"
	assert_output --partial "Explain code or technical concepts"
	assert_output --partial "ARGUMENTS:"
	assert_output --partial "OPTIONS:"
	assert_output --partial "--context"
	assert_output --partial "--detail"
	assert_output --partial "--format"
}

@test "ai-action: explain basic query" {
	run_script "ai-action" "explain" "What is recursion?"
	assert_success
	assert_output --partial "AI Explanation"
	assert_output --partial "Concept:"
	assert_output --partial "Key Points:"
	assert_output --partial "Explanation completed successfully"
}

@test "ai-action: explain with programming context" {
	run_script "ai-action" "explain" --context "programming" "hash tables"
	assert_success
	assert_output --partial "Programming Concept:"
	assert_output --partial "computational problems"
	assert_output --partial "algorithm design"
}

@test "ai-action: explain with system context" {
	run_script "ai-action" "explain" --context "system" "memory management"
	assert_success
	assert_output --partial "System Concept:"
	assert_output --partial "hardware-software interaction"
	assert_output --partial "resource management"
}

@test "ai-action: explain with network context" {
	run_script "ai-action" "explain" --context "network" "TCP/IP"
	assert_success
	assert_output --partial "Network Concept:"
	assert_output --partial "data transmission"
	assert_output --partial "protocol layers"
}

@test "ai-action: explain with advanced detail" {
	run_script "ai-action" "explain" --detail "advanced" "test concept"
	assert_success
	assert_output --partial "Advanced Details:"
	assert_output --partial "Technical implementation"
	assert_output --partial "Performance optimization"
}

@test "ai-action: explain with markdown format" {
	run_script "ai-action" "explain" --format "markdown" "test concept"
	assert_success
	assert_output --partial "Markdown format:"
	assert_output --partial "# test concept"
	assert_output --partial "## Overview"
	assert_output --partial "## Examples"
}

@test "ai-action: explain without query fails" {
	run_script "ai-action" "explain"
	assert_failure
	assert_output --partial "Query is required for explanation"
}

# API key warning tests
@test "ai-action: shows API key warning for AI commands" {
	run_script "ai-action" "analyze" --text "test"
	assert_success
	assert_output --partial "No API key provided. Using simulated responses"
	assert_output --partial "Set AI_API_KEY environment variable"
}

@test "ai-action: no API key warning for explain command" {
	run_script "ai-action" "explain" "test"
	assert_success
	# explain command doesn't require API key warning
	refute_output --partial "No API key provided"
}

# Error handling tests
@test "ai-action: analyze unknown option" {
	run_script "ai-action" "analyze" --unknown
	assert_failure
	assert_output --partial "Unknown option for analyze command: --unknown"
}

@test "ai-action: generate unknown option" {
	run_script "ai-action" "generate" --unknown
	assert_failure
	assert_output --partial "Unknown option for generate command: --unknown"
}

@test "ai-action: translate unknown option" {
	run_script "ai-action" "translate" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
}

@test "ai-action: summarize unknown option" {
	run_script "ai-action" "summarize" --unknown
	assert_failure
	assert_output --partial "Unknown option for summarize command: --unknown"
}

@test "ai-action: code-review unknown option" {
	run_script "ai-action" "code-review" --unknown
	assert_failure
	assert_output --partial "Unknown option for code-review command: --unknown"
}

@test "ai-action: explain unknown option" {
	run_script "ai-action" "explain" --unknown
	assert_failure
	assert_output --partial "Unknown option: --unknown"
}

# Combined options tests
@test "ai-action: analyze with multiple options" {
	run_script "ai-action" "analyze" --text "test" --type "sentiment" --format "json"
	assert_success
	assert_output --partial "Sentiment:"
	assert_output --partial "JSON Output:"
}

@test "ai-action: generate with multiple options" {
	run_script "ai-action" "generate" --prompt "test" --type "code" --creativity "high"
	assert_success
	assert_output --partial "sort_array()"
}

@test "ai-action: global options with commands" {
	run_script "ai-action" --verbose --model "gpt-4" "explain" "test query"
	assert_success
	assert_output --partial "AI Explanation"
}

# Integration-style tests
@test "ai-action: complete workflow simulation" {
	# Test a sequence of commands that might be used together
	run_script "ai-action" "analyze" --text "Sample text for analysis"
	assert_success

	run_script "ai-action" "summarize" --text "Long content that needs to be summarized for easier understanding"
	assert_success

	run_script "ai-action" "explain" "artificial intelligence"
	assert_success
}

@test "ai-action: all commands have consistent output format" {
	# Verify that all commands produce properly formatted output
	local commands=("analyze --text 'test'" "generate --prompt 'test'" "translate --to spanish 'hello'" "summarize --text 'test'" "explain 'test'" "code-review --file $TEST_FILE")

	for cmd in "${commands[@]}"; do
		run bash -c "'${PROJECT_ROOT}/demo/ai-action' $cmd"
		assert_success
		# Should not have obvious formatting issues
		refute_output --partial "ERROR"
		refute_output --partial "command not found"
	done
}

# File handling edge cases
@test "ai-action: commands handle file paths with spaces" {
	local spaced_file
	spaced_file=$(mktemp -u)
	spaced_file="${spaced_file} with spaces.txt"
	echo "Test content" > "$spaced_file"

	run_script "ai-action" "analyze" --file "$spaced_file"
	assert_success
	assert_output --partial "Analysis completed successfully"

	# Clean up
	rm "$spaced_file"
}

@test "ai-action: commands handle empty files gracefully" {
	local empty_file
	empty_file=$(mktemp)

	run_script "ai-action" "analyze" --file "$empty_file"
	assert_success
	assert_output --partial "AI Analysis Results"

	# Clean up
	rm "$empty_file"
}