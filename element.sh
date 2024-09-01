#!/bin/bash
PSQL=$(echo "psql -X --username=freecodecamp --dbname=periodic_table --tuples-only --no-align -c")

MAIN(){
  if [[ -z $1 ]]
    then
    echo "Please provide an element as an argument."
    else
    ELEMENTS $1
  fi
}
FIX_DB(){
  MOTANIUM=$($PSQL "SELECT COUNT(*) FROM elements WHERE atomic_number=1000;")
  if [[ $MOTANIUM -gt 0 ]]
    then
    #weight to atomic_mass
    WEIGHT_TO_ATOMIC=$($PSQL "ALTER TABLE properties RENAME COLUMN weight TO atomic_mass;")

    #melting_point to melting_point_celsius
    MELTING=$($PSQL "ALTER TABLE properties RENAME COLUMN melting_point TO melting_point_celsius;")

    #boiling_point to boiling_point_celsius
    BOILING=$($PSQL "ALTER TABLE properties RENAME COLUMN boiling_point TO boiling_point_celsius;")

    #melting and boiling not null
    M_NOT=$($PSQL "ALTER TABLE properties ALTER COLUMN melting_point_celsius SET NOT NULL;")
    B_NOT=$($PSQL "ALTER TABLE properties ALTER COLUMN boiling_point_celsius SET NOT NULL;")
    
    #symbol and name UNIQUE
    SYMBOL_U=$($PSQL "ALTER TABLE elements ADD UNIQUE(symbol);")
    NAME_U=$($PSQL "ALTER TABLE elements ADD UNIQUE(name);")
    
    #symbol and name NOT NULL
    SYMBOL_NOT=$($PSQL "ALTER TABLE elements ALTER COLUMN symbol SET NOT NULL;")
    NAME_NOT=$($PSQL "ALTER TABLE elements ALTER COLUMN name SET NOT NULL;")
    
    #foreign key atomic_number on properties and elements
    ELE_PRO=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY(atomic_number) REFERENCES elements(atomic_number);")
    
    #Create types
    TYPES=$($PSQL "CREATE TABLE types();")
    
    #add type_id
    TYPE_ID=$($PSQL "ALTER TABLE types ADD COLUMN type_id INT PRIMARY KEY;")
    
    #add type
    TYPE=$($PSQL "ALTER TABLE types ADD COLUMN type VARCHAR(30) NOT NULL;")
    
    #Insert types
    INSERTS=$($PSQL "INSERT INTO types(type_id,type) VALUES(1,'nonmetal'),(2,'metal'),(3,'metalloid');")
    
    #Add type_id to properties, update values before FK, then foreign key
    TYPE_ID_P=$($PSQL "ALTER TABLE properties ADD COLUMN type_id INT;")
    UPDATEA=$($PSQL "UPDATE properties SET type_id=1 WHERE type='nonmetal';")
    UPDATEB=$($PSQL "UPDATE properties SET type_id=2 WHERE type='metal';")
    UPDATEC=$($PSQL "UPDATE properties SET type_id=3 WHERE type='metalloid';")
    TYPE_ID_NOT=$($PSQL "ALTER TABLE properties ALTER COLUMN type_id SET NOT NULL;")
    FOREIGN_K=$($PSQL "ALTER TABLE properties ADD FOREIGN KEY(type_id) REFERENCES types(type_id);")
    
    #capitalize symbol and elements
    CAPITALIZE=$($PSQL "UPDATE elements SET symbol=INITCAP(symbol);")
    
    #remove trailing zeros using atomic_mass.txt
    ALTER_TYPE=$($PSQL "ALTER TABLE properties ALTER COLUMN atomic_mass TYPE VARCHAR(9);")
    UPDATE_FLOAT=$($PSQL "UPDATE properties SET atomic_mass=CAST(atomic_mass AS FLOAT);")
    
    #Add first element
    INSERT_FLUO=$($PSQL "INSERT INTO elements(atomic_number,symbol,name) VALUES(9,'F','Fluorine');")
    INSERT_FLUOP=$($PSQL "INSERT INTO properties(atomic_number,type,atomic_mass,melting_point_celsius,boiling_point_celsius,type_id) VALUES(9,'nonmetal','18.998',-220,-188.1,1);")
    INSERT_NEON=$($PSQL "INSERT INTO elements(atomic_number,symbol,name) VALUES(10,'Ne','Neon');")
    INSERT_NEONP=$($PSQL "INSERT INTO properties(atomic_number,type,atomic_mass,melting_point_celsius,boiling_point_celsius,type_id) VALUES(10,'nonmetal','20.18',-248.6,-246.1),1;")
    
    #delete elemnt whose atomic_number is 1000
    DELETE_MOTANIUMP=$($PSQL "DELETE FROM properties WHERE atomic_number=1000;")
    DELETE_MOTANIUME=$($PSQL "DELETE FROM elements WHERE atomic_number=1000;")
    
    #properties should not have type column
    DROP_TYPE_P=$($PSQL "ALTER TABLE properties DROP COLUMN type;")
    
    #finished dabase fix
    clear
  fi
  MAIN $1
}

ELEMENTS(){
  #here we go T_T
  #check the input
  INPUT=$1
  #its not a number?
  if [[ ! $INPUT =~ ^[0-9]+$ ]]
    then
    #not a number, check on symbol or name
    ATOMIC_NUMBER=$($PSQL "SELECT atomic_number FROM elements WHERE symbol='$INPUT' OR name='$INPUT';")
    else
    #its actually a number
    ATOMIC_NUMBER=$($PSQL "SELECT atomic_number FROM elements WHERE atomic_number=$INPUT;")
  fi
  #query done, check if exist on db
  if [[ -z $ATOMIC_NUMBER ]]
    then
    #failed on query(not exist)
    echo "I could not find that element in the database."
    else
    #do the querys to echo the final message
    NAME=$($PSQL "SELECT name FROM elements WHERE atomic_number=$ATOMIC_NUMBER;")
    SYMBOL=$($PSQL "SELECT symbol FROM elements WHERE atomic_number=$ATOMIC_NUMBER;")
    TYPE=$($PSQL "SELECT type FROM elements FULL JOIN properties USING(atomic_number) INNER JOIN types USING(type_id) WHERE atomic_number=$ATOMIC_NUMBER;")
    ATOMIC_MASS=$($PSQL "SELECT atomic_mass FROM properties WHERE atomic_number=$ATOMIC_NUMBER;")
    MELTING_POINT=$($PSQL "SELECT melting_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER;")
    BOILING_POINT=$($PSQL "SELECT boiling_point_celsius FROM properties WHERE atomic_number=$ATOMIC_NUMBER;")

    echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $ATOMIC_MASS amu. $NAME has a melting point of $MELTING_POINT celsius and a boiling point of $BOILING_POINT celsius."
  fi
}

FIX_DB $1