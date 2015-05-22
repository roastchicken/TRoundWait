if not SERVER then return end

--number of rounds before the probability change occurs
troundwait_rounds = CreateConVar( "troundwait_rounds", "10", FCVAR_ARCHIVE )
--probability for forcing traitor rounds. any value between 0 and 1.
troundwait_probabilty = CreateConVar( "troundwait_probability", "1", FCVAR_ARCHIVE )

if not sql.TableExists( "troundwait" ) then
	sql.Query( "CREATE TABLE IF NOT EXISTS troundwait ( id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, player INTEGER NOT NULL, rounds INTEGER NOT NULL );" )
	sql.Query( "CREATE INDEX IDX_TROUNDWAIT_PLAYER ON troundwait ( player DESC );" )
end

function onRoundStart()
  ServerLog("onRoundStart ran\n")
  local innos = {}

  for k,v in pairs(player.GetAll()) do
    if IsValid(v) and (not v:IsSpec()) then
      if not v:IsTraitor() then
        table.insert(innos, v:UniqueID())
      end
    end
  end
  
  logInnocents(innos)
  setTraitors(checkRounds(innos))
  
end

hook.Add( "TTTBeginRound", "TRoundWaitRoundStart", onRoundStart )

function logInnocents( table )
  ServerLog("logInnocents ran\n")
  for k,v in pairs(table) do
    local row = sql.QueryRow( "SELECT rounds FROM troundwait WHERE player = " .. v .. ";" )
    
    if row then
      sql.Query( "UPDATE troundwait SET rounds = " .. row.rounds + 1 .. " WHERE player = " .. v .. ";" )
    else
      sql.Query( "INSERT into troundwait ( player, rounds ) VALUES ( " .. v .. ", 1 );" )
    end
  end
end

function checkRounds( table )
  ServerLog("checkRounds ran\n")
  local ts = {}

  for k,v in pairs(table) do
    local row = sql.QueryRow( "SELECT rounds FROM troundwait WHERE player = " .. v .. " AND rounds >= " .. troundwait_rounds:GetInt() .. " ;" )
    
    if row then
      table.insert(ts, v)
      sql.Query( "UPDATE troundwait SET rounds = 0 WHERE player = " .. v .. ";" )
    end
  end
  
  return ts
end

function setTraitors( table )
  ServerLog("setTraitors ran\n")
  for k,v in pairs(table) do
    rand = math.random()
    if rand < troundwait_probability:GetInt() then
      v:SetRole(ROLE_TRAITOR)
      ServerLog(v .. "was made a traitor\n")
    end
  end
end
