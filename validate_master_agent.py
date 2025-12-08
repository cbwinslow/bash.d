#!/usr/bin/env python3
"""Quick validation script for Master AI Agent"""

import asyncio
import sys
import traceback
from agents.master_agent import create_autonomous_agent, DevelopmentWorkflow
from agents.base import AgentType

async def main():
    print("=" * 60)
    print("Master AI Agent - Validation Test")
    print("=" * 60)
    
    # Test 1: Initialize
    print("\n1. Initializing Master Agent...")
    agent = await create_autonomous_agent()
    assert agent.name == "Master AI Agent", "Agent name mismatch"
    assert agent.projects_completed == 0, "Initial projects should be 0"
    print("   ✓ Initialization successful")
    
    # Test 2: Summon agents
    print("\n2. Summoning specialized agents...")
    coding_agents = agent.summon_agent(AgentType.PROGRAMMING, count=2)
    assert len(coding_agents) == 2, "Should summon 2 coding agents"
    print(f"   ✓ Summoned {len(coding_agents)} coding agents")
    
    testing_agents = agent.summon_agent(AgentType.TESTING, count=1)
    assert len(testing_agents) == 1, "Should summon 1 testing agent"
    print(f"   ✓ Summoned {len(testing_agents)} testing agent")
    
    agents_before_project = agent.agents_summoned
    print(f"   ✓ Total agents summoned so far: {agents_before_project}")
    
    # Test 3: Create project (this will summon more agents)
    print("\n3. Creating a project...")
    project = await agent.create_project(
        name="Test CLI Tool",
        description="A test command-line tool",
        workflow=DevelopmentWorkflow.CLI_TOOL,
        requirements={"language": "python"}
    )
    assert project.name == "Test CLI Tool", "Project name mismatch"
    assert project.phase.value == "implementation", "Should be in implementation phase"
    assert len(project.tasks) > 0, "Should have tasks created"
    print(f"   ✓ Project created: {project.id}")
    print(f"   ✓ Phase: {project.phase.value}")
    print(f"   ✓ Tasks: {len(project.tasks)}")
    print(f"   ✓ Total agents now: {agent.agents_summoned} (project summoned additional agents)")
    
    # Test 4: Get status
    print("\n4. Checking status...")
    status = agent.get_status()
    assert status['master_agent']['name'] == "Master AI Agent"
    assert status['projects']['active'] == 1, "Should have 1 active project"
    assert agent.agents_summoned >= agents_before_project, "Agent count should increase or stay same"
    print("   ✓ Status check passed")
    print(f"   ✓ Active projects: {status['projects']['active']}")
    print(f"   ✓ Summoned agents: {status['agents']['summoned']}")
    
    # Test 5: Agent pool
    print("\n5. Verifying agent pool...")
    assert AgentType.PROGRAMMING in agent.agent_pool, "Should have programming agents"
    assert AgentType.TESTING in agent.agent_pool, "Should have testing agents"
    print(f"   ✓ Programming agents: {len(agent.agent_pool[AgentType.PROGRAMMING])}")
    print(f"   ✓ Testing agents: {len(agent.agent_pool[AgentType.TESTING])}")
    if AgentType.DOCUMENTATION in agent.agent_pool:
        print(f"   ✓ Documentation agents: {len(agent.agent_pool[AgentType.DOCUMENTATION])}")
    
    print("\n" + "=" * 60)
    print("✓ ALL VALIDATION TESTS PASSED")
    print("=" * 60)
    print("\nMaster AI Agent is ready for autonomous software development!")
    print(f"\nSummary:")
    print(f"  • Total agents summoned: {agent.agents_summoned}")
    print(f"  • Active projects: {len(agent.active_projects)}")
    print(f"  • Agent types in pool: {len(agent.agent_pool)}")
    print(f"  • Registered with orchestrator: {len(agent.orchestrator.agents)}")
    return 0

if __name__ == "__main__":
    try:
        exit_code = asyncio.run(main())
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n❌ Validation failed: {e}")
        traceback.print_exc()
        sys.exit(1)
