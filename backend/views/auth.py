from datetime import datetime, timedelta, timezone
import json
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from db import db
from models import(
    RoleType,
    User,
    UserRole,
    Mentor
) 
from werkzeug.security import check_password_hash, generate_password_hash

auth_bp = Blueprint("auth", __name__)

# login
@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    print("data:", data)
    email = data.get("email")
    password = data.get("password")
    mentor_id = None

    # find user
    # in case of shared emails, the user is shared, too 
    # with that email
    user = User.query.filter(User.email==email).first()
    # no user or password incorrect: error
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({"msg": "Bad email or password"}), 401
    
    # check user's roles
    roles = [
        role.role.value 
        for role in UserRole.query.filter_by(
            user_id=user.id
            ).all()
        ]
    # no role: error
    if len(roles) == 0:
        return jsonify ({"msg": "No role found"}), 403
    # multipe roles: temporary token
    if 1 < len(roles):
        temp_token_roles = create_access_token(
            identity=json.dumps({
                'id': user.id, 
                'roles': roles
                }),
            expires_delta=timedelta(minutes=5)
            )
        print("temporary token:", temp_token_roles)
        return jsonify({
            "msg": "Specify role",
            "access_token": temp_token_roles, 
            "roles": roles
            })
    role = roles[0]

    # check mentor candidates
    if role == RoleType.MENTOR.value:
        mentor_records = Mentor.query.filter(Mentor.user_id == user.id).all()
        mentors = [
            {
                "id": mentor.id,
                "first_name": mentor.first_name,
                "last_name": mentor.last_name
            }
            for mentor in mentor_records 

        ]
        print("mentors:", mentors)
        # no mentor candidates: error
        if len(mentors) == 0:
            return jsonify({"msg": "No mentor found"}), 403
        # multiple candidates: temporary token
        if 1 < len(mentors):
            temp_token = create_access_token(
                identity=json.dumps({
                    'id': user.id, 
                    "mentor_ids":[m["id"] for m in mentors], 
                    'role': role
                    }),
                expires_delta=timedelta(minutes=5)
                )
            return jsonify({
                "msg": "Specify mentor",
                "access_token": temp_token, 
                "mentors": mentors
                })
        mentor_id = mentors[0]["id"]
    # admin role or single mentor candidate: final token
    access_token = create_access_token(
        identity=json.dumps({
            "id": user.id, 
            "role": role
            }))
    return jsonify({
        "access_token": access_token, 
        "role": role
        }), 200

@auth_bp.route('/specify_role', methods=['POST'])
@jwt_required()
def specify_role():
    identity = json.loads(get_jwt_identity())
    id = identity["id"]
    roles = identity["roles"]
    data = request.get_json()
    role = data.get("role")
    print("role:", role)
    if not role:
        return jsonify({"msg": "Role not specified"}), 400
    if role not in roles:
        return jsonify({"msg": "Wrong role specified"}), 400
    # role specified: final token
    access_token = create_access_token(
        identity=json.dumps({
            "id": id, 
            "role": role
            }))
    return jsonify({
        "access_token": access_token,
        "role": role
        }), 200    


@auth_bp.route('/specify_mentor', methods=['POST'])
@jwt_required()
def specify_mentor():
    identity = json.loads(get_jwt_identity())
    id = identity["id"]
    mentor_ids = identity["mentor_ids"]
    role = identity["role"]
    data = request.get_json()
    mentor_id = data.get("mentor_id")
    if not mentor_id:
        return jsonify({"msg": "Mentor not specified"}), 400
    if mentor_id not in mentor_ids:
        return jsonify({"msg": "Wrong mentor specified"}), 400
    # mentor specified: final token
    access_token = create_access_token(
        identity=json.dumps({
        "id": id, 
        "role": role,
        "mentor_id": mentor_id
        }))
    return jsonify({
        "access_token": access_token,
        "role": role
        }), 200    

# password change
@auth_bp.route('/passwdchange', methods=['POST'])
@jwt_required()
def change_password():
    data = request.get_json()
    old_password = data.get("oldPassword")
    new_password = data.get("newPassword")
    identity = json.loads(get_jwt_identity())
    id = identity.get("id")
    print(id)

    # verify old password
    user = User.query.filter_by(id=id).first()
    if not check_password_hash(user.password_hash, old_password):
        return jsonify({"msg": "Old password is incorrect"}), 401
    else:
        # update password
        user.password_hash = generate_password_hash(new_password)
        db.session.commit()
        return jsonify({"msg": "Password updated successfully"}), 200

# role validation
@auth_bp.route('/validate/<role>', methods=['POST'])
@jwt_required()
def validate_role(role):
    def get_preferred_language(id):
        try:
            user = Mentor.query.filter(Mentor.user_id == id).first()
            language = user.preferred_language
        except:
            language = "en"
        return language
    
    if role == "temporary":
        return jsonify({"msg": "authorized"}), 200 

    identity = json.loads(get_jwt_identity())
    role_from_token = identity.get("role")
    id = identity.get("id", [])
    print("variants:", role, role_from_token)
    
    # Check if the user has the specified role
    if role == role_from_token:
        if role == "mentor":
            preferred_language = get_preferred_language(id)
            print("Preferred language set to:", preferred_language)
            return jsonify({
                "msg": "authorized", 
                "preferred_language":  preferred_language
                })
        else:        
            return jsonify({"msg": "authorized"}), 200
    else:
        return jsonify({"msg": f"{role.capitalize()}s only!"}), 403


