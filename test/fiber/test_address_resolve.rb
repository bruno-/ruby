# frozen_string_literal: true
require 'test/unit'
require_relative 'scheduler'

class TestAddressResolve < Test::Unit::TestCase
  def test_addrinfo_getaddrinfo
    finished_order = []

    Thread.new do
      scheduler = Scheduler.new
      Fiber.set_scheduler scheduler

      Fiber.schedule do
        result = Addrinfo.getaddrinfo("localhost", 80, :AF_INET, :STREAM)
        finished_order << 1
        assert_equal(1, result.count)

        ai = result.first
        # NOTE: ai.dup == ai # false
        assert_equal("127.0.0.1", ai.ip_address)
        assert_equal(80, ai.ip_port)
        assert_equal(Socket::AF_INET, ai.afamily)
        assert_equal(Socket::SOCK_STREAM, ai.socktype)
      end

      Fiber.schedule do
        finished_order << 2
      end
    end.join

    assert_equal([2, 1], finished_order)
  end
end
