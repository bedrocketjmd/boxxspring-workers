module Boxxspring
  module Synchronization

    self.const_set 'Operations', {

      lock: 
        "local result = false; "\
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) then "\
          "redis.call( 'set', KEYS[ 1 ], ARGV[ 1 ] ); "\
          "result = true; "\
        "elseif value == ARGV[ 1 ] then "\
          "result = true; "\
        "end; "\
        "if result == true and not ( ARGV[ 2 ] == '' ) then "\
          "redis.call( 'pexpire', KEYS[ 1 ], ARGV[ 2 ] ); "\
        "end; "\
        "return result",

      unlock: 
        "local result = false; "\
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) then "\
          "result = true; "\
        "elseif value == ARGV[ 1 ] then "\
          "redis.call( 'del', KEYS[ 1 ] ); "\
          "result = true; "\
        "else "\
          "result = false; "\
        "end; " \
        "return result",

      write_if_greater_than: 
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) or ( ARGV[ 1 ] > value ) then "\
          "redis.call( 'set', KEYS[ 1 ], ARGV[ 1 ] ); "\
          "return true; "\
        "else "\
          "return false;"\
        "end",

      write_if_greater_than_or_equal_to: 
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) or ( ARGV[ 1 ] >= value ) then "\
          "redis.call( 'set', KEYS[ 1 ], ARGV[ 1 ] ); "\
          "return true; "\
        "else "\
          "return false;"\
        "end",

      write_if_equal_to: 
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) or ( ARGV[ 1 ] == value ) then "\
          "redis.call( 'set', KEYS[ 1 ], ARGV[ 1 ] ); "\
          "return true; "\
        "else "\
          "return false;"\
        "end",
        
      write_if_less_than_or_equal_to: 
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) or ( ARGV[ 1 ] <= value ) then "\
          "redis.call( 'set', KEYS[ 1 ], ARGV[ 1 ] ); "\
          "return true; "\
        "else "\
          "return false;"\
        "end",

      write_if_less_than: 
        "local value = redis.call( 'get', KEYS[ 1 ] ); "\
        "if ( not value ) or ( ARGV[ 1 ] < value ) then "\
          "redis.call( 'set', KEYS[ 1 ], ARGV[ 1 ] ); "\
          "return true; "\
        "else "\
          "return false;"\
        "end"
        
    }    

  end
end