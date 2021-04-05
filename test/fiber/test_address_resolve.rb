# frozen_string_literal: true
require 'test/unit'
require_relative 'scheduler'

class TestAddressResolve < Test::Unit::TestCase
  class NullScheduler < Scheduler
    def address_resolve(*)
    end
  end

  class StubScheduler < Scheduler
    def address_resolve(hostname, timeout = nil)
      ["1.2.3.4", "1234:1234:123:1:123:1234:1234:1234"]
    end
  end

  def test_addrinfo_getaddrinfo_localhost_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.getaddrinfo("localhost", 80, :AF_INET, :STREAM)
        assert_equal(1, result.count)

        ai = result.first
        # NOTE: ai.dup == ai # false
        assert_equal("127.0.0.1", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end
    end.join
  end

  def test_addrinfo_getaddrinfo_domain_blocking
    Thread.new do
      scheduler = StubScheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.getaddrinfo("example.com", 80, :AF_INET, :STREAM)
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("1.2.3.4", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end
    end.join
  end

  def test_addrinfo_getaddrinfo_numeric_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.getaddrinfo("4.3.2.1", 80, :AF_INET, :STREAM)
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("1.2.3.4", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end
    end.join
  end

  def test_addrinfo_getaddrinfo_any_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.getaddrinfo("<any>", 80, :AF_INET, :STREAM)
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("0.0.0.0", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end
    end.join
  end

  def test_addrinfo_getaddrinfo_non_existing_domain_blocking
    Thread.new do
      scheduler = NullScheduler.new # invoked, returns nil
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        error_msg = "getaddrinfo: nodename nor servname provided, or not known"
        assert_raise_with_message(SocketError, error_msg) {
          Addrinfo.getaddrinfo("non-existing-domain.abc", nil)
        }
      end
    end.join
  end

  def test_addrinfo_getaddrinfo_no_host_non_blocking
    Thread.new do
      scheduler = NullScheduler.new # scheduler hook not invoked
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.getaddrinfo(nil, 80, :AF_INET, :STREAM)
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("127.0.0.1", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end
    end.join
  end

  def test_addrinfo_ip_domain_blocking
    Thread.new do
      scheduler = StubScheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.ip("example.com")
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("1.2.3.4", ai.ip_address)
      end
    end.join
  end

  def test_addrinfo_tcp_domain_blocking
    Thread.new do
      scheduler = StubScheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.tcp("example.com", 80)
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("1.2.3.4", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end
    end.join
  end

  def test_addrinfo_udp_domain_blocking
    Thread.new do
      scheduler = StubScheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.udp("example.com", 80)
        assert_equal(1, result.count)

        ai = result.first
        assert_equal("1.2.3.4", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_DGRAM, ai.socktype)
      end
    end.join
  end

  def test_tcp_socket_gethostbyname_domain_blocking
    Thread.new do
      scheduler = StubScheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = TCPSocket.gethostbyname("example.com")

        assert_equal([
          "example.com",
          Socket::AF_INET,
          "1.2.3.4",
          "1234:1234:123:1:123:1234:1234:1234"
        ], result)
      end
    end.join
  end
end
