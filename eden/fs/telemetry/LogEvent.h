/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

#pragma once

#include <string>
#include <unordered_map>

namespace facebook {
namespace eden {

class DynamicEvent {
 public:
  using IntMap = std::unordered_map<std::string, int64_t>;
  using StringMap = std::unordered_map<std::string, std::string>;
  using DoubleMap = std::unordered_map<std::string, double>;

  DynamicEvent() = default;
  DynamicEvent(const DynamicEvent&) = default;
  DynamicEvent(DynamicEvent&&) = default;
  DynamicEvent& operator=(const DynamicEvent&) = default;
  DynamicEvent& operator=(DynamicEvent&&) = default;

  void addInt(std::string name, int64_t value);
  void addString(std::string name, std::string value);
  void addDouble(std::string name, double value);

  /**
   * Convenience function that adds boolean values as integer 0 or 1.
   */
  void addBool(std::string name, bool value) {
    addInt(std::move(name), value);
  }

  const IntMap& getIntMap() const {
    return ints_;
  }
  const StringMap& getStringMap() const {
    return strings_;
  }
  const DoubleMap& getDoubleMap() const {
    return doubles_;
  }

 private:
  // Due to limitations in the underlying log database, limit the field types to
  // int64_t, double, string, and vector<string>
  // TODO: add vector<string> support if needed.
  IntMap ints_;
  StringMap strings_;
  DoubleMap doubles_;
};

struct DaemonStart {
  static constexpr const char* type = "daemon_start";

  double duration = 0.0;

  void populate(DynamicEvent& event) const {
    event.addDouble("duration", duration);
  }
};

struct FinishedCheckout {
  static constexpr const char* type = "checkout";

  double duration = 0.0;
  bool success = false;

  void populate(DynamicEvent& event) const {
    event.addDouble("duration", duration);
    event.addBool("success", success);
  }
};

struct FuseError {
  static constexpr const char* type = "fuse_error";

  int64_t fuseOp = 0;
  int64_t errorCode = 0;

  void populate(DynamicEvent& event) const {
    event.addInt("fuse_op", fuseOp);
    event.addInt("error_code", errorCode);
  }
};

struct RocksDbAutomaticGc {
  static constexpr const char* type = "rocksdb_autogc";

  double duration = 0.0;
  bool success = false;
  int64_t sizeBefore = 0;
  int64_t sizeAfter = 0;

  void populate(DynamicEvent& event) const {
    event.addDouble("duration", duration);
    event.addBool("success", success);
    event.addInt("size_before", sizeBefore);
    event.addInt("size_after", sizeAfter);
  }
};

struct ThriftError {
  static constexpr const char* type = "thrift_error";

  std::string thriftMethod;

  void populate(DynamicEvent& event) const {
    event.addString("method", thriftMethod);
  }
};

struct ThriftAuthFailure {
  static constexpr const char* type = "thrift_auth_failure";

  std::string thriftMethod;
  std::string reason;

  void populate(DynamicEvent& event) const {
    event.addString("method", thriftMethod);
    event.addString("reason", reason);
  }
};

} // namespace eden
} // namespace facebook
