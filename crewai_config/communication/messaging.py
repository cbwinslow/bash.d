"""
Multi-Agent Communication System

Provides messaging infrastructure for agent-to-agent and crew-to-crew communication
using RabbitMQ, Redis Pub/Sub, and other protocols.
"""

import json
import logging
from typing import Optional, Dict, Any, Callable, List
from datetime import datetime
from enum import Enum
import asyncio

try:
    import pika
    RABBITMQ_AVAILABLE = True
except ImportError:
    RABBITMQ_AVAILABLE = False

try:
    import redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False

from ..schemas.crew_models import CrewCommunication

logger = logging.getLogger(__name__)


class MessageType(str, Enum):
    """Types of messages"""
    TASK_REQUEST = "task_request"
    TASK_RESPONSE = "task_response"
    VOTE_REQUEST = "vote_request"
    VOTE_CAST = "vote_cast"
    PROPOSAL = "proposal"
    STATUS_UPDATE = "status_update"
    BROADCAST = "broadcast"
    PEER_MESSAGE = "peer_message"
    ERROR = "error"


class Message:
    """Standard message format for agent communication"""
    
    def __init__(
        self,
        message_type: MessageType,
        sender_id: str,
        sender_name: str,
        content: Dict[str, Any],
        receiver_id: Optional[str] = None,
        crew_id: Optional[str] = None,
        correlation_id: Optional[str] = None
    ):
        self.message_type = message_type
        self.sender_id = sender_id
        self.sender_name = sender_name
        self.receiver_id = receiver_id
        self.crew_id = crew_id
        self.content = content
        self.correlation_id = correlation_id
        self.timestamp = datetime.utcnow()
        self.id = f"{sender_id}_{int(self.timestamp.timestamp() * 1000)}"
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "id": self.id,
            "type": self.message_type.value,
            "sender_id": self.sender_id,
            "sender_name": self.sender_name,
            "receiver_id": self.receiver_id,
            "crew_id": self.crew_id,
            "content": self.content,
            "correlation_id": self.correlation_id,
            "timestamp": self.timestamp.isoformat()
        }
    
    def to_json(self) -> str:
        """Convert to JSON string"""
        return json.dumps(self.to_dict())
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Message':
        """Create message from dictionary"""
        msg = cls(
            message_type=MessageType(data["type"]),
            sender_id=data["sender_id"],
            sender_name=data["sender_name"],
            content=data["content"],
            receiver_id=data.get("receiver_id"),
            crew_id=data.get("crew_id"),
            correlation_id=data.get("correlation_id")
        )
        msg.id = data.get("id", msg.id)
        if "timestamp" in data:
            msg.timestamp = datetime.fromisoformat(data["timestamp"])
        return msg
    
    @classmethod
    def from_json(cls, json_str: str) -> 'Message':
        """Create message from JSON string"""
        return cls.from_dict(json.loads(json_str))


class RabbitMQMessenger:
    """RabbitMQ-based messaging for agents"""
    
    def __init__(
        self,
        host: str = "localhost",
        port: int = 5672,
        username: str = "guest",
        password: str = "guest",
        exchange: str = "crew_exchange"
    ):
        if not RABBITMQ_AVAILABLE:
            raise ImportError("pika not installed. Install with: pip install pika")
        
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.exchange = exchange
        
        self.connection: Optional[pika.BlockingConnection] = None
        self.channel: Optional[pika.channel.Channel] = None
        self.message_handlers: Dict[str, Callable] = {}
        
    def connect(self) -> None:
        """Establish connection to RabbitMQ"""
        credentials = pika.PlainCredentials(self.username, self.password)
        parameters = pika.ConnectionParameters(
            host=self.host,
            port=self.port,
            credentials=credentials
        )
        
        self.connection = pika.BlockingConnection(parameters)
        self.channel = self.connection.channel()
        
        # Declare exchange
        self.channel.exchange_declare(
            exchange=self.exchange,
            exchange_type='topic',
            durable=True
        )
        
        logger.info(f"Connected to RabbitMQ at {self.host}:{self.port}")
    
    def disconnect(self) -> None:
        """Close connection"""
        if self.connection and not self.connection.is_closed:
            self.connection.close()
            logger.info("Disconnected from RabbitMQ")
    
    def publish(
        self,
        message: Message,
        routing_key: str
    ) -> None:
        """
        Publish a message
        
        Args:
            message: Message to publish
            routing_key: Routing key for message
        """
        if not self.channel:
            self.connect()
        
        self.channel.basic_publish(
            exchange=self.exchange,
            routing_key=routing_key,
            body=message.to_json(),
            properties=pika.BasicProperties(
                delivery_mode=2,  # Persistent
                content_type='application/json',
                correlation_id=message.correlation_id
            )
        )
        
        logger.debug(f"Published message: {message.id} -> {routing_key}")
    
    def subscribe(
        self,
        queue_name: str,
        routing_keys: List[str],
        callback: Callable[[Message], None]
    ) -> None:
        """
        Subscribe to messages
        
        Args:
            queue_name: Name of the queue
            routing_keys: List of routing keys to bind
            callback: Function to call when message received
        """
        if not self.channel:
            self.connect()
        
        # Declare queue
        self.channel.queue_declare(queue=queue_name, durable=True)
        
        # Bind routing keys
        for routing_key in routing_keys:
            self.channel.queue_bind(
                exchange=self.exchange,
                queue=queue_name,
                routing_key=routing_key
            )
        
        # Set up consumer
        def on_message(ch, method, properties, body):
            try:
                message = Message.from_json(body.decode())
                callback(message)
                ch.basic_ack(delivery_tag=method.delivery_tag)
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                ch.basic_nack(delivery_tag=method.delivery_tag)
        
        self.channel.basic_consume(
            queue=queue_name,
            on_message_callback=on_message
        )
        
        logger.info(f"Subscribed to queue: {queue_name}")
    
    def start_consuming(self) -> None:
        """Start consuming messages"""
        if not self.channel:
            raise RuntimeError("Not connected to RabbitMQ")
        
        logger.info("Starting to consume messages...")
        self.channel.start_consuming()


class RedisMessenger:
    """Redis Pub/Sub messaging for agents"""
    
    def __init__(
        self,
        host: str = "localhost",
        port: int = 6379,
        db: int = 0,
        password: Optional[str] = None
    ):
        if not REDIS_AVAILABLE:
            raise ImportError("redis not installed. Install with: pip install redis")
        
        self.host = host
        self.port = port
        self.db = db
        self.password = password
        
        self.client: Optional[redis.Redis] = None
        self.pubsub: Optional[redis.client.PubSub] = None
        self.message_handlers: Dict[str, Callable] = {}
    
    def connect(self) -> None:
        """Connect to Redis"""
        self.client = redis.Redis(
            host=self.host,
            port=self.port,
            db=self.db,
            password=self.password,
            decode_responses=True
        )
        
        self.pubsub = self.client.pubsub()
        logger.info(f"Connected to Redis at {self.host}:{self.port}")
    
    def disconnect(self) -> None:
        """Disconnect from Redis"""
        if self.pubsub:
            self.pubsub.close()
        if self.client:
            self.client.close()
        logger.info("Disconnected from Redis")
    
    def publish(self, channel: str, message: Message) -> None:
        """
        Publish message to channel
        
        Args:
            channel: Channel name
            message: Message to publish
        """
        if not self.client:
            self.connect()
        
        self.client.publish(channel, message.to_json())
        logger.debug(f"Published to Redis channel: {channel}")
    
    def subscribe(
        self,
        channels: List[str],
        callback: Callable[[str, Message], None]
    ) -> None:
        """
        Subscribe to channels
        
        Args:
            channels: List of channel names
            callback: Function to call with (channel, message)
        """
        if not self.pubsub:
            self.connect()
        
        self.pubsub.subscribe(*channels)
        
        # Store callback
        for channel in channels:
            self.message_handlers[channel] = callback
        
        logger.info(f"Subscribed to Redis channels: {channels}")
    
    async def listen(self) -> None:
        """Listen for messages asynchronously"""
        if not self.pubsub:
            raise RuntimeError("Not connected to Redis")
        
        logger.info("Starting to listen for Redis messages...")
        
        for message in self.pubsub.listen():
            if message['type'] == 'message':
                channel = message['channel']
                data = message['data']
                
                try:
                    msg = Message.from_json(data)
                    
                    if channel in self.message_handlers:
                        callback = self.message_handlers[channel]
                        
                        if asyncio.iscoroutinefunction(callback):
                            await callback(channel, msg)
                        else:
                            callback(channel, msg)
                
                except Exception as e:
                    logger.error(f"Error processing Redis message: {e}")


class CrewMessagingHub:
    """
    Central messaging hub for crew communication
    
    Manages both RabbitMQ and Redis messaging for a crew
    """
    
    def __init__(
        self,
        crew_id: str,
        config: CrewCommunication,
        rabbitmq_config: Optional[Dict[str, Any]] = None,
        redis_config: Optional[Dict[str, Any]] = None
    ):
        self.crew_id = crew_id
        self.config = config
        
        # Initialize messengers
        self.rabbitmq: Optional[RabbitMQMessenger] = None
        if config.rabbitmq_enabled and RABBITMQ_AVAILABLE:
            self.rabbitmq = RabbitMQMessenger(**(rabbitmq_config or {}))
        
        self.redis: Optional[RedisMessenger] = None
        if config.redis_enabled and REDIS_AVAILABLE:
            self.redis = RedisMessenger(**(redis_config or {}))
        
        self.message_log: List[Message] = []
    
    def connect(self) -> None:
        """Connect all messaging systems"""
        if self.rabbitmq:
            self.rabbitmq.connect()
        if self.redis:
            self.redis.connect()
    
    def disconnect(self) -> None:
        """Disconnect all messaging systems"""
        if self.rabbitmq:
            self.rabbitmq.disconnect()
        if self.redis:
            self.redis.disconnect()
    
    def send_message(
        self,
        message: Message,
        routing_key: Optional[str] = None,
        channel: Optional[str] = None
    ) -> None:
        """
        Send a message using available protocols
        
        Args:
            message: Message to send
            routing_key: RabbitMQ routing key
            channel: Redis channel
        """
        # Send via RabbitMQ
        if self.rabbitmq and routing_key:
            self.rabbitmq.publish(message, routing_key)
        
        # Send via Redis
        if self.redis and channel:
            self.redis.publish(channel, message)
        
        # Log message
        self.message_log.append(message)
    
    def broadcast(self, message: Message) -> None:
        """
        Broadcast message to all crew members
        
        Args:
            message: Message to broadcast
        """
        message.message_type = MessageType.BROADCAST
        
        broadcast_key = f"crew.{self.crew_id}.broadcast"
        self.send_message(message, routing_key=broadcast_key, channel=broadcast_key)
    
    def send_to_agent(self, message: Message, agent_id: str) -> None:
        """
        Send message to specific agent
        
        Args:
            message: Message to send
            agent_id: Target agent ID
        """
        message.receiver_id = agent_id
        
        routing_key = f"crew.{self.crew_id}.agent.{agent_id}"
        channel = f"agent_{agent_id}"
        
        self.send_message(message, routing_key=routing_key, channel=channel)
    
    def request_vote(
        self,
        proposal_id: str,
        proposal_description: str,
        sender_id: str,
        sender_name: str
    ) -> None:
        """
        Request votes from crew members
        
        Args:
            proposal_id: ID of proposal
            proposal_description: Description of proposal
            sender_id: ID of requesting agent
            sender_name: Name of requesting agent
        """
        message = Message(
            message_type=MessageType.VOTE_REQUEST,
            sender_id=sender_id,
            sender_name=sender_name,
            crew_id=self.crew_id,
            content={
                "proposal_id": proposal_id,
                "description": proposal_description
            }
        )
        
        self.broadcast(message)
    
    def get_message_stats(self) -> Dict[str, Any]:
        """Get messaging statistics"""
        return {
            "crew_id": self.crew_id,
            "total_messages": len(self.message_log),
            "rabbitmq_enabled": self.rabbitmq is not None,
            "redis_enabled": self.redis is not None,
            "message_types": {
                msg_type.value: sum(
                    1 for m in self.message_log if m.message_type == msg_type
                )
                for msg_type in MessageType
            }
        }
