delimiter $$;

drop function if exists get_hash;
create function get_hash(block int, nonce int, data varchar(256), prev char(32))
  returns char(32)
  begin
  declare i varchar(500);
  declare hash_all char(32);
  set i=(select concat(block, nonce, data, prev));
  set hash_all=(select md5(i));
  return hash_all;
  end;
-- get hash

drop function if exists is_block_valid;
create function is_block_valid(block int, nonce int, data varchar(256), prev char(32))
  returns boolean
  begin
  declare hash_all char(32);
  declare hash_left char(4);
  declare result int;

  set hash_all=(select get_hash(block, nonce, data, prev));
  set hash_left=(select left(hash_all, 4));
  set result=(select strcmp(hash_left, '0000'));
  if result=0 then
  return true;
  else
  return false;
  end if;
  end;
-- make sure the block is valid

drop function if exists get_valid_nonce;
create function get_valid_nonce(block int, data varchar(256), prev char(32))
  returns int
  begin
  declare result int default 0;
  while not is_block_valid(block, result, data, prev) do
  set result=result+1;
  end while;
  return result;
  end;
-- get valid nonce

-- select is_block_valid(1, 68466, '', '00000000000000000000000000000000')

-- for test

drop procedure if exists create_initial_block;
create procedure create_initial_block()
  begin
  declare data varchar(256);
  declare nonce int;

  drop table if exists block_chain;
  create table block_chain
    (
      block int primary key not null auto_increment,
      nonce int not null default 0,
      data varchar(256),
      prev char(32) not null,
      hash char(32) not null
    );
  -- create table
  set data='first block';
  set nonce=(select get_valid_nonce(1, data, '00000000000000000000000000000000'));
  -- get valid nonce
  insert into block_chain
    (
      nonce,
      data,
      prev,
      hash
    )
     values
    (
      nonce,
      data,
      '00000000000000000000000000000000',
      (select get_hash(1, nonce, data, '00000000000000000000000000000000'))
    );
  -- create initial block
  end;

drop procedure if exists check_block_chain;
create procedure check_block_chain()
  begin
  update block_chain set hash=get_hash(block, nonce, data, prev);
  select * from block_chain;
  select is_block_valid(block, nonce, data, prev), not strcmp(get_hash(block, nonce, data, prev), hash) from block_chain;
  select b.block, not strcmp(a.prev, b.hash) from block_chain a, block_chain b where a.block-b.block=1;
  end;


drop procedure if exists mine;
create procedure mine(data_mine varchar(256))
  begin
  declare block_mine int;
  declare nonce_mine int;
  declare prev_mine char(32);
  set block_mine=(select block from block_chain order by block desc limit 1) + 1;
  set prev_mine=(select hash from block_chain order by block desc limit 1);
  set nonce_mine=(select get_valid_nonce(block_mine, data_mine, prev_mine));
  select block_mine, data_mine, nonce_mine, prev_mine;
  -- select is_block_valid(block, nonce, data, prev);
  insert into block_chain
    (
      nonce,
      data,
      prev,
      hash
    )
     values
    (
      nonce_mine,
      data_mine,
      prev_mine,
      (select get_hash(block_mine, nonce_mine, data_mine, prev_mine))
    );
  select * from block_chain;
  end;
call create_initial_block();
-- select * from block_chain;
call mine('second');
call mine('third');
call mine('fourth');
call mine('fifth');
call check_block_chain();
update block_chain set data='fake data' where block=3;
call check_block_chain();
