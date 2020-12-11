# frozen_string_literal: true
require 'test/unit'
require_relative 'scheduler'

class TestNameResolve < Test::Unit::TestCase
  class NullScheduler < Scheduler
    def name_resolve(*)
    end
  end

  class StubScheduler < Scheduler
    def name_resolve(ip_address)
      "example.com"
    end
  end

  def test_socket_getnameinfo_localhost_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Socket.getnameinfo([:AF_INET, 80, "127.0.0.1"])

        assert_equal(["localhost", "http"], result)
      end
    end.join
  end

  def test_socket_getnameinfo_address_blocking
    Thread.new do
      scheduler = StubScheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Socket.getnameinfo([:AF_INET, 80, "1.2.3.4"])

        assert_equal(["example.com", "http"], result)
      end
    end.join
  end

  def test_socket_getnameinfo_address_numeric_hostname_flag_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Socket.getnameinfo([:AF_INET, 80, "1.2.3.4"], Socket::NI_NUMERICHOST)

        assert_equal(["1.2.3.4", "http"], result)
      end
    end.join
  end

  def test_socket_getnameinfo_address_nil_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Socket.getnameinfo([:AF_INET, 80, nil])

        assert_equal(["localhost", "http"], result)
      end
    end.join
  end

  def test_socket_getnameinfo_unresolved_address_blocking
    Thread.new do
      scheduler = NullScheduler.new # invoked, returns nil
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Socket.getnameinfo([:AF_INET, 80, "4.3.2.1"])

        assert_equal(["4.3.2.1", "http"], result)
      end
    end.join
  end

  def test_socket_getnameinfo_unresolved_address_namereqd_flag_blocking
    Thread.new do
      scheduler = NullScheduler.new # invoked, returns nil
      Fiber.set_scheduler scheduler

      error_msg = "getnameinfo: nodename nor servname provided, or not known"
      Fiber.schedule do
        assert_raise_with_message(SocketError, error_msg) {
          Socket.getnameinfo([:AF_INET, 80, "4.3.2.1"], Socket::NI_NAMEREQD)
        }
      end
    end.join
  end
end
