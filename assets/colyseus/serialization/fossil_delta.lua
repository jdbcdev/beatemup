local msgpack = require('colyseus.messagepack.MessagePack')
local delta = require('colyseus.serialization.fossil_delta.fossil_delta')
local StateContainer = require('colyseus.state_listener.state_container')
local utils = require('colyseus.utils')

local fossil_delta = {}
fossil_delta.__index = fossil_delta

function fossil_delta.new ()
  local instance = {
    state = StateContainer.new(),
    previous_state = nil
  }
  setmetatable(instance, fossil_delta)
  return instance
end

function fossil_delta:get_state()
  return self.state.state
end

function fossil_delta:set_state(encoded_state, it)
  local state_length, state = msgpack.unpacker(encoded_state)()
  it.offset = it.offset + state_length

  self.state:set(state)

  self.previous_state = utils.string_to_byte_array(encoded_state)
end

function fossil_delta:patch(binary_patch, it)
  -- apply patch
  self.previous_state = delta.apply(self.previous_state, utils.string_to_byte_array(binary_patch))
  it.offset = it.offset + #self.previous_state

  -- decode patched state
  local new_state = msgpack.unpack( utils.byte_array_to_string(self.previous_state) )

  -- trigger state callbacks
  self.state:set( new_state )
end

function fossil_delta:teardown()
  return self.state:remove_all_listeners()
end

return fossil_delta
